#!/usr/bin/env python3

"""
PDF processing script to create Spacy Docs from PDF documents.
This script uses Spacy-layout for document processing and structure analysis.
"""

import os
import sys
import argparse
from pathlib import Path
import json
from typing import List, Dict, Any, Tuple, Union, Optional

# PDF processing
import fitz  # type: ignore # PyMuPDF (imported as fitz)

# NLP
import spacy  # type: ignore
from spacy.tokens import Doc, Span  # type: ignore
from spacy.language import Language  # type: ignore
from spacy_layout import LayoutModel  # type: ignore


def extract_text_from_pdf(pdf_path: Union[str, Path]) -> List[Dict[str, Any]]:
    """
    Extract text and layout information from a PDF using PyMuPDF.
    
    Args:
        pdf_path: Path to the PDF file
        
    Returns:
        List of dictionaries containing text blocks with position information
    """
    if isinstance(pdf_path, str):
        pdf_path = Path(pdf_path)
    
    # Open the PDF
    doc = fitz.open(str(pdf_path))
    
    all_blocks = []
    
    # Process each page
    for page_num, page in enumerate(doc):
        # Extract text with layout information
        blocks = page.get_text("dict")["blocks"]
        
        for block in blocks:
            if "lines" in block:
                for line in block["lines"]:
                    if "spans" in line:
                        for span in line["spans"]:
                            # Extract text and position
                            text = span["text"]
                            if not text.strip():
                                continue
                                
                            # Get bounding box (x0, y0, x1, y1)
                            bbox = (span["bbox"][0], span["bbox"][1], 
                                   span["bbox"][2], span["bbox"][3])
                            
                            # Get font information
                            font = span["font"]
                            size = span["size"]
                            
                            all_blocks.append({
                                "text": text,
                                "bbox": bbox,
                                "page": page_num + 1,
                                "font": font,
                                "size": size
                            })
    
    print(f"Extracted {len(all_blocks)} text blocks from {pdf_path}")
    return all_blocks


def create_spacy_doc(text_blocks: List[Dict[str, Any]], nlp: Any) -> Doc:
    """
    Create a Spacy Doc from extracted text blocks.
    
    Args:
        text_blocks: List of text blocks with position information
        nlp: Spacy NLP pipeline
        
    Returns:
        Spacy Doc with layout information
    """
    # Combine all text from blocks
    full_text = " ".join([block["text"] for block in text_blocks])
    
    # Create a basic Spacy Doc
    doc = nlp(full_text)
    
    # Add layout information to the Doc
    if hasattr(doc, "spans") and "layout" in doc.spans:
        # If using spacy-layout, we can add layout information
        for block in text_blocks:
            # Create a span for each text block
            text = block["text"]
            start = full_text.find(text)
            
            # Skip if text not found (should not happen)
            if start == -1:
                continue
                
            end = start + len(text)
            
            # Find token indices that correspond to these character indices
            start_token = None
            end_token = None
            for i, token in enumerate(doc):
                if token.idx <= start < token.idx + len(token.text):
                    start_token = i
                if token.idx <= end <= token.idx + len(token.text):
                    end_token = i + 1
                    break
            
            if start_token is not None and end_token is not None and start_token < end_token:
                # Create a span with layout information
                span = Span(
                    doc, 
                    start_token, 
                    end_token, 
                    label="LAYOUT_ELEMENT"
                )
                
                # Add metadata
                span._.set("bbox", block["bbox"])
                span._.set("page", block["page"])
                span._.set("font", block["font"])
                span._.set("size", block["size"])
                
                # Add to layout spans
                doc.spans["layout"].append(span)
    
    return doc


def analyze_document_structure(doc: Doc) -> Dict[str, Any]:
    """
    Analyze the document structure using Spacy-layout.
    
    Args:
        doc: Spacy Doc with layout information
        
    Returns:
        Dictionary with document structure analysis
    """
    structure: Dict[str, Any] = {
        "title": None,
        "headings": [],
        "paragraphs": [],
        "entities": []
    }
    
    # Extract entities
    for ent in doc.ents:
        structure["entities"].append({
            "text": ent.text,
            "label": ent.label_,
            "start": ent.start_char,
            "end": ent.end_char
        })
    
    # Extract document structure if layout spans are available
    if hasattr(doc, "spans") and "layout" in doc.spans:
        # Find potential title (largest font on first page)
        title_candidates = [
            span for span in doc.spans["layout"] 
            if span._.get("page") == 1 and len(span.text) > 3
        ]
        
        if title_candidates:
            # Sort by font size (descending)
            title_candidates.sort(key=lambda x: x._.get("size", 0), reverse=True)
            structure["title"] = title_candidates[0].text
        
        # Find headings (larger font than surrounding text)
        all_sizes = [span._.get("size", 0) for span in doc.spans["layout"]]
        if all_sizes:
            avg_size = sum(all_sizes) / len(all_sizes)
            
            for span in doc.spans["layout"]:
                size = span._.get("size", 0)
                if size > avg_size * 1.2 and len(span.text) < 100:
                    structure["headings"].append({
                        "text": span.text,
                        "page": span._.get("page"),
                        "size": size
                    })
        
        # Extract paragraphs (consecutive spans with similar properties)
        current_paragraph = ""
        current_page = 1
        
        for span in sorted(doc.spans["layout"], key=lambda x: (x._.get("page", 1), x._.get("bbox", (0,0,0,0))[1])):
            page = span._.get("page", 1)
            
            # If we moved to a new page or there's a significant vertical gap
            if page != current_page:
                if current_paragraph:
                    structure["paragraphs"].append({
                        "text": current_paragraph.strip(),
                        "page": current_page
                    })
                    current_paragraph = ""
                current_page = page
            
            current_paragraph += " " + span.text
        
        # Add the last paragraph
        if current_paragraph:
            structure["paragraphs"].append({
                "text": current_paragraph.strip(),
                "page": current_page
            })
    
    return structure


def save_doc(doc: Doc, output_path: Union[str, Path]) -> None:
    """
    Save a Spacy Doc to disk.
    
    Args:
        doc: Spacy Doc to save
        output_path: Path to save the Doc
    """
    if isinstance(output_path, str):
        output_path = Path(output_path)
    
    os.makedirs(output_path.parent, exist_ok=True)
    
    # Save the Doc
    doc.to_disk(str(output_path))
    print(f"Saved Spacy Doc to {output_path}")


def main() -> None:
    """Main function to process PDF and create Spacy Doc."""
    parser = argparse.ArgumentParser(description="Process PDF and create Spacy Doc")
    parser.add_argument("pdf_path", help="Path to the PDF file")
    parser.add_argument("--output", "-o", help="Output path for Spacy Doc", default=None)
    parser.add_argument("--model", "-m", help="Spacy model to use", default="en_core_web_sm")
    parser.add_argument("--analyze", "-a", action="store_true", help="Analyze document structure")
    args = parser.parse_args()
    
    # Set default output path if not provided
    if args.output is None:
        pdf_path = Path(args.pdf_path)
        args.output = str(pdf_path.with_suffix(".spacy"))
    
    # Load Spacy model
    print(f"Loading Spacy model: {args.model}")
    try:
        nlp = spacy.load(args.model)
    except OSError:
        print(f"Model {args.model} not found. Downloading...")
        spacy.cli.download(args.model)
        nlp = spacy.load(args.model)
    
    # Add layout component if available
    try:
        layout = LayoutModel()
        nlp.add_pipe("layout", after="ner")
        print("Added layout component to pipeline")
    except Exception as e:
        print(f"Could not add layout component: {e}")
    
    # Extract text from PDF
    text_blocks = extract_text_from_pdf(args.pdf_path)
    
    # Create Spacy Doc from text blocks
    doc = create_spacy_doc(text_blocks, nlp)
    
    # Save Doc
    save_doc(doc, args.output)
    
    # Analyze document structure if requested
    if args.analyze:
        structure = analyze_document_structure(doc)
        
        # Print document structure
        print("\nDocument Structure:")
        if structure["title"]:
            print(f"Title: {structure['title']}")
        
        print(f"\nHeadings ({len(structure['headings'])}):")
        for i, heading in enumerate(structure["headings"][:5]):
            print(f"  {i+1}. {heading['text']} (Page {heading['page']})")
        if len(structure["headings"]) > 5:
            print(f"  ... and {len(structure['headings']) - 5} more")
        
        print(f"\nParagraphs: {len(structure['paragraphs'])}")
        print(f"Entities: {len(structure['entities'])}")
    
    # Print summary
    print("\nSummary:")
    print(f"Processed PDF: {args.pdf_path}")
    print(f"Extracted {len(text_blocks)} text blocks")
    print(f"Created Spacy Doc with {len(doc)} tokens")
    print(f"Named entities found: {len(doc.ents)}")
    if hasattr(doc, "spans") and "layout" in doc.spans:
        print(f"Layout elements: {len(doc.spans['layout'])}")
    
    # Print sample of processed text
    print("\nSample of processed text:")
    print(doc.text[:500] + "..." if len(doc.text) > 500 else doc.text)


if __name__ == "__main__":
    main()
