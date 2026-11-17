"""
Crawler for Coptic Library Books
Fetches books from authorized library and saves metadata and content.
"""
import urllib.request
import re
import json
import os
import time

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
}

def get_html(url):
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.read().decode('utf-8', errors='ignore')
    except Exception as e:
        print(f"Error fetching {url}: {e}")
        return ""

def scrape_book_page(book_url):
    html = get_html(book_url)
    if not html:
        return None
    
    # Title
    title_match = re.search(r'<h1[^>]*>(.*?)</h1>', html, re.DOTALL)
    title = re.sub(r'<[^>]+>', '', title_match.group(1)).strip() if title_match else ""
    
    # Description / Content paragraphs
    paragraphs = re.findall(r'<p[^>]*>(.*?)</p>', html, re.DOTALL)
    clean_paragraphs = [re.sub(r'<[^>]+>', '', p).strip() for p in paragraphs if len(p.strip()) > 30]
    
    # PDF link if any
    pdf_match = re.search(r'href=[\'"]([^\'"]+\.pdf[^\'"]*)[\'"]', html)
    pdf_url = pdf_match.group(1) if pdf_match else ""

    slug = book_url.rstrip('/').split('/')[-1]
    
    if not title:
        title = slug.replace('-', ' ').title()
        
    return {
        "id": slug,
        "title": title,
        "author": "مكتبة الكنيسة القبطية الأرثوذكسية",
        "category_id": "general",
        "category_name": "كتب ودراسات كنسية",
        "description": clean_paragraphs[0] if clean_paragraphs else "كتاب ودراسة كنسية نافعة للنمو الروحي.",
        "cover_icon": "📚",
        "pdf_url": pdf_url,
        "chapters_count": max(1, len(clean_paragraphs)),
        "chapters": [
            {
                "id": f"{slug}_ch_{i+1}",
                "chapter_number": i + 1,
                "title": f"المقطع {i + 1}",
                "content": p
            } for i, p in enumerate(clean_paragraphs[:5])
        ]
    }

def main():
    print("Scraping books from library...")
    index_url = "https://stgeorgesaman.com/libraries/books/"
    html = get_html(index_url)
    if not html:
        print("Failed to fetch books index.")
        return
        
    book_links = re.findall(r'href=[\'"](https?://stgeorgesaman\.com/books/[^\'"]+)[\'"]', html)
    unique_links = list(set(book_links))
    print(f"Found {len(unique_links)} books to inspect.")
    
    # Load existing books
    books_file = "assets/data/books.json"
    existing_books = []
    if os.path.exists(books_file):
        with open(books_file, "r", encoding="utf-8") as f:
            existing_books = json.load(f)
            
    existing_ids = {b["id"] for b in existing_books}
    
    for url in unique_links[:6]:
        b = scrape_book_page(url)
        if b and b["id"] not in existing_ids and len(b["chapters"]) > 0:
            existing_books.append(b)
            print(f"Added book: {b['title']} with {len(b['chapters'])} sections.")
            existing_ids.add(b["id"])
        time.sleep(0.3)
        
    with open(books_file, "w", encoding="utf-8") as f:
        json.dump(existing_books, f, ensure_ascii=False, indent=2)
    print(f"Total books now in library: {len(existing_books)}")

if __name__ == "__main__":
    main()
