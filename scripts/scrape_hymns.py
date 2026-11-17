"""
Scrapes hymns from the authorized Coptic library and creates assets/data/hymns.json
Extracts MP3 audio links and 3-column table:
1) Coptic text
2) Arabized Coptic pronunciation
3) Arabic meaning
"""
import urllib.request
import re
import json
import os
import time

BASE_URL = "https://stgeorgesaman.com/libraries/hymns-library/"

# Selected curated categories across the library
CATEGORY_URLS = [
    {
        "category_id": "feasts",
        "category_name": "المناسبات والأعياد الكبرى",
        "url": "https://stgeorgesaman.com/libraries/hymns-library/occasionsandfeasts/resurrection/"
    },
    {
        "category_id": "pascha",
        "category_name": "أسبوع الآلام والبصخة المقدسة",
        "url": "https://stgeorgesaman.com/libraries/hymns-library/occasionsandfeasts/pascha/"
    },
    {
        "category_id": "annual_praise",
        "category_name": "التسبحة السنوية والكيهكية",
        "url": "https://stgeorgesaman.com/libraries/hymns-library/praise/midnight-praise/"
    },
    {
        "category_id": "liturgy",
        "category_name": "الصلوات والقداسات الإلهية",
        "url": "https://stgeorgesaman.com/libraries/hymns-library/prayersandservices/liturgy/"
    }
]

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
}

def get_html(url):
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.read().decode('utf-8', errors='ignore')
    except Exception as e:
        print(f"Error fetching {url}: {e}")
        return ""

def extract_hymn_links_from_category(cat_url):
    html = get_html(cat_url)
    if not html:
        return []
    # Find links under /libraries/hymns-library/
    links = re.findall(r'href=[\'"](https?://stgeorgesaman\.com/libraries/hymns-library/[^\'"]+)[\'"]', html)
    # Filter out top-level parent pages
    sub_links = []
    for l in set(links):
        parts = [p for p in l.split('/') if p]
        if len(parts) >= 6: # sufficiently deep
            sub_links.append(l)
    return sub_links

def parse_hymn(hymn_url, category_id, category_name):
    html = get_html(hymn_url)
    if not html:
        return None
    
    # Extract Title from H1 or H2
    title_match = re.search(r'<h1[^>]*>(.*?)</h1>', html, re.DOTALL) or re.search(r'<h2[^>]*>(.*?)</h2>', html, re.DOTALL)
    title = re.sub(r'<[^>]+>', '', title_match.group(1)).strip() if title_match else ""
    if not title or "مكتبة" in title:
        slug = hymn_url.rstrip('/').split('/')[-1]
        title = slug.replace('-', ' ').title()
    
    # Extract Audio URL
    audio_match = re.search(r'https?://[^\s"\'<>]+\.mp3', html)
    audio_url = audio_match.group(0) if audio_match else ""
    
    # Extract Cantor name if present in URL or page
    cantor = "المعلم إبراهيم عياد والخوروس"
    if "cantor" in audio_url.lower():
        cantor_parts = re.findall(r'cantor_([a-z_]+)', audio_url.lower())
        if cantor_parts:
            name_norm = cantor_parts[0].replace('_', ' ').title()
            if "Ibrahim" in name_norm or "Ayad" in name_norm:
                cantor = "المعلم إبراهيم عياد"
            else:
                cantor = f"المعلم {name_norm}"

    # Extract 3-column rows
    verses = []
    rows = re.findall(r'<tr[^>]*>(.*?)</tr>', html, re.DOTALL)
    for row in rows:
        cells = re.findall(r'<td[^>]*>(.*?)</td>', row, re.DOTALL)
        if len(cells) >= 3:
            coptic = re.sub(r'<[^>]+>', '', cells[0]).strip()
            arabized = re.sub(r'<[^>]+>', '', cells[1]).strip()
            arabic = re.sub(r'<[^>]+>', '', cells[2]).strip()
            # Clean non-breaking spaces
            coptic = coptic.replace('&nbsp;', ' ').strip()
            arabized = arabized.replace('&nbsp;', ' ').strip()
            arabic = arabic.replace('&nbsp;', ' ').strip()
            if (coptic or arabized or arabic) and not (coptic == "القبطي" and arabic == "العربي"):
                verses.append({
                    "coptic": coptic,
                    "arabized": arabized,
                    "arabic": arabic
                })
    
    if not audio_url and not verses:
        return None
        
    slug = hymn_url.rstrip('/').split('/')[-1]
    return {
        "id": slug,
        "title": title,
        "category_id": category_id,
        "category_name": category_name,
        "cantor": cantor,
        "audio_url": audio_url,
        "verses_count": len(verses),
        "verses": verses
    }

def main():
    print("Starting hymns extraction...")
    os.makedirs("assets/data", exist_ok=True)
    all_hymns = []
    
    # Gather hymn links
    collected_urls = set()
    for cat in CATEGORY_URLS:
        print(f"Scanning category: {cat['category_name']}")
        links = extract_hymn_links_from_category(cat['url'])
        print(f"  Found {len(links)} links")
        for l in links[:8]: # Grab top representative hymns per category
            if l not in collected_urls:
                collected_urls.add((l, cat['category_id'], cat['category_name']))
    
    print(f"Total targeted hymns to extract: {len(collected_urls)}")
    for url, cat_id, cat_name in collected_urls:
        print(f"Parsing: {url}")
        hymn_data = parse_hymn(url, cat_id, cat_name)
        if hymn_data and (hymn_data["audio_url"] or hymn_data["verses"]):
            all_hymns.append(hymn_data)
            print(f"  -> Added '{hymn_data['title']}' with {hymn_data['verses_count']} verses, audio: {bool(hymn_data['audio_url'])}")
        time.sleep(0.3)
        
    output_path = "assets/data/hymns.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(all_hymns, f, ensure_ascii=False, indent=2)
    print(f"\nSuccessfully saved {len(all_hymns)} hymns to {output_path}!")

if __name__ == "__main__":
    main()
