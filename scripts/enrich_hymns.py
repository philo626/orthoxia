import json

with open("assets/data/hymns.json", "r", encoding="utf-8") as f:
    hymns = json.load(f)

# Add more prominent classics with tri-lingual verses & audio
additional_hymns = [
    {
        "id": "first-doxology-of-resurrection",
        "title": "الذكصولوجية الأولى لعيد القيامة المجيد",
        "category_id": "feasts",
        "category_name": "المناسبات والأعياد الكبرى",
        "cantor": "المعلم إبراهيم عياد والخوروس",
        "audio_url": "https://media.stgeorgesaman.com/uploads/2021/05/first-doxology-of-resurrection-cantor_ibrahim_ayad-coptic_lan-stgeorgesaman.com.mp3",
        "verses_count": 8,
        "verses": [
            {
                "coptic": "Ⲧⲟⲧⲉ ⲁϥⲱϣ ⲉⲃⲟⲗ",
                "arabized": "توطي آف أوش إيفول",
                "arabic": "حينئذ صرخ قائلاً"
            },
            {
                "coptic": "ϫⲉ ⲱ ⲡⲁⲥⲱⲧⲏⲣ",
                "arabized": "جيه أو با سوتير",
                "arabic": "يا مخلصي"
            },
            {
                "coptic": "ⲁⲕⲓ̀ ⲁⲕⲥⲱϯ ⲙ̀ⲙⲟⲓ",
                "arabized": "آك إي آك سوتي إمموي",
                "arabic": "أتيت وخلصتني"
            },
            {
                "coptic": "ⲉ̀ⲃⲟⲗ ϧⲉⲛ ⲁⲙⲉⲛϯ",
                "arabized": "إيفول خين آمينتي",
                "arabic": "من الجحيم"
            },
            {
                "coptic": "Ⲡⲓⲭ̀ⲣⲓⲥⲧⲟⲥ ⲁϥⲧⲱⲛϥ ⲉ̀ⲃⲟⲗ ϧⲉⲛ ⲛⲏⲉⲑⲙⲱⲟⲩⲧ",
                "arabized": "بي إخرستوس أفتونف إيفول خين ني إثموؤوت",
                "arabic": "المسيح قام من بين الأموات"
            },
            {
                "coptic": "ϧⲉⲛ ⲟⲩⲙⲉⲑⲙⲏϣ ⲛ̀ⲥⲱⲧⲏⲣ",
                "arabized": "خين أو ميثميش إن سوتير",
                "arabic": "بخلاص عظيم"
            },
            {
                "coptic": "ⲁϥϣⲁⲛ ⲛ̀ⲛⲓⲕⲉⲗⲓ ⲛ̀ⲧⲉ ⲡⲓⲙⲟⲩ",
                "arabized": "آفشان إن ني كيلي إنتي بي مو",
                "arabic": "وداس أوجاع الموت"
            },
            {
                "coptic": "ⲁⲗⲗⲏⲗⲟⲩⲓⲁ ⲁⲗⲗⲏⲗⲟⲩⲓⲁ",
                "arabized": "الليلويا الليلويا",
                "arabic": "هلليلويا هلليلويا"
            }
        ]
    },
    {
        "id": "tai-shouri-hazzayni",
        "title": "لحن طاي شوري الحزايني",
        "category_id": "pascha",
        "category_name": "أسبوع الآلام والبصخة المقدسة",
        "cantor": "المعلم إبراهيم عياد",
        "audio_url": "https://media.stgeorgesaman.com/uploads/2021/05/tai-shouri-cantor_ibrahim_ayad-coptic_lan-stgeorgesaman.com.mp3",
        "verses_count": 6,
        "verses": [
            {
                "coptic": "Ⲧⲁⲓϣⲟⲩⲣⲏ ⲛ̀ⲛⲟⲩⲃ ⲛ̀ⲕⲁⲑⲁⲣⲟⲥ",
                "arabized": "طاي شوري إن نوب إن كاثا روس",
                "arabic": "هذه المجمرة الذهب النقي"
            },
            {
                "coptic": "ⲉⲧⲫⲁⲓ ϧⲁ ⲡⲓϫⲱⲙ ⲛ̀ⲁⲣⲱⲙⲁⲧⲁ",
                "arabized": "إتفاي خا بي جوم إن آروماتا",
                "arabic": "الحاملة جمر البخور"
            },
            {
                "coptic": "ⲉⲧϧⲉⲛ ⲛⲉⲛϫⲓϫ ⲛ̀Ⲁⲁⲣⲱⲛ ⲡⲓⲟⲩⲏⲃ",
                "arabized": "إتخين نين جيج إن آأرون بي أوويب",
                "arabic": "التي في يدي هارون الكاهن"
            },
            {
                "coptic": "ⲉϥⲧⲁⲗⲟ ⲉ̀ⲡ̀ϣⲱⲓ ⲛ̀ⲟⲩⲥ̀ⲑⲟⲓⲛⲟⲩϥⲓ",
                "arabized": "إف طالو إي إبشوي إن أو إسثوي نوفي",
                "arabic": "وهو يصعد بخوراً طيباً"
            },
            {
                "coptic": "ⲉ̀ϩ̀ⲣⲏⲓ ⲉ̀ϫⲉⲛ ⲡⲓⲙⲁⲛ̀ⲉⲣϣⲱⲟⲩϣⲓ",
                "arabized": "إيهري إيجين بي مان إير شوؤوشي",
                "arabic": "على المذبح المقدس"
            },
            {
                "coptic": "ϯⲡⲁⲣⲑⲉⲛⲟⲥ ⲧⲉ Ϯⲑⲉⲟ̀ⲧⲟⲕⲟⲥ",
                "arabized": "تي بارثينوس تي تي ثيئوطوكوس",
                "arabic": "هي العذراء والدة الإله"
            }
        ]
    },
    {
        "id": "fay-etaf-enf",
        "title": "لحن فاي إيطاف إنف (هذا الذي أصعد ذاته)",
        "category_id": "pascha",
        "category_name": "أسبوع الآلام والبصخة المقدسة",
        "cantor": "المعلم إبراهيم عياد والخوروس",
        "audio_url": "https://media.stgeorgesaman.com/uploads/2021/05/fay-etaf-enf-cantor_ibrahim_ayad-coptic_lan-stgeorgesaman.com.mp3",
        "verses_count": 6,
        "verses": [
            {
                "coptic": "Ⲫⲁⲓ ⲉ̀ⲧⲁϥⲉⲛϥ ⲉ̀ⲡ̀ϣⲱⲓ",
                "arabized": "فاي إيطاف إنف إي إبشوي",
                "arabic": "هذا الذي أصعد ذاته"
            },
            {
                "coptic": "ⲛ̀ⲟⲩⲑⲩⲥⲓⲁ ⲉⲥϣⲏⲡ",
                "arabized": "إن أو ثيسيا إس شيب",
                "arabic": "ذبيحة مقبولة"
            },
            {
                "coptic": "ⲉ̀ϩ̀ⲣⲏⲓ ⲉ̀ϫⲉⲛ ⲡⲓⲥ̀ⲧⲁⲩⲣⲟⲥ",
                "arabized": "إيهري إيجين بي إستافروس",
                "arabic": "على عود الصليب"
            },
            {
                "coptic": "ϧⲁ ⲡ̀ⲟⲩϫⲁⲓ ⲙ̀ⲡⲉⲛⲅⲉⲛⲟⲥ",
                "arabized": "خا إبؤوجاي إمبين جينوس",
                "arabic": "عن خلاص جنسنا"
            },
            {
                "coptic": "ⲁϥϣⲱⲗⲡ ⲉ̀ⲣⲟϥ ⲛ̀ϫⲉ ⲡⲉϥⲓⲱⲧ ⲛ̀ⲁ̀ⲅⲁⲑⲟⲥ",
                "arabized": "آف شولب إيروف إنجيه بيف يوت إن أغاثوس",
                "arabic": "فاشتمه أبوه الصالح"
            },
            {
                "coptic": "ϧⲉⲛ ⲡⲓⲅⲟⲗⲅⲟⲑⲁ",
                "arabized": "خين بي غولغوثا",
                "arabic": "في الجلجثة"
            }
        ]
    },
    {
        "id": "e-ep-ouro",
        "title": "لحن إبؤورو (يا ملك السلام)",
        "category_id": "annual_praise",
        "category_name": "التسبحة السنوية والكيهكية",
        "cantor": "المعلم إبراهيم عياد",
        "audio_url": "https://media.stgeorgesaman.com/uploads/2021/05/e-ep-ouro-cantor_ibrahim_ayad-coptic_lan-stgeorgesaman.com.mp3",
        "verses_count": 6,
        "verses": [
            {
                "coptic": "Ⲡⲟⲩⲣⲟ ⲛ̀ⲧⲉ ϯϩⲓⲣⲏⲛⲏ",
                "arabized": "إبؤورو إنتي تي هيريني",
                "arabic": "يا ملك السلام"
            },
            {
                "coptic": "ⲙⲟⲓ ⲛⲁⲛ ⲛ̀ⲧⲉⲕϩⲓⲣⲏⲛⲏ",
                "arabized": "موي نان إنتيك هيريني",
                "arabic": "أعطنا سلامك"
            },
            {
                "coptic": "ⲥⲉⲙⲛⲓ ⲛⲁⲛ ⲛ̀ⲧⲉⲕϩⲓⲣⲏⲛⲏ",
                "arabized": "سيمني نان إنتيك هيريني",
                "arabic": "قرر لنا سلامك"
            },
            {
                "coptic": "ⲭⲁ ⲛⲉⲛⲛⲟⲃⲓ ⲛⲁⲛ ⲉ̀ⲃⲟⲗ",
                "arabized": "خا نين نوفي نان إيفول",
                "arabic": "واغفر لنا خطايانا"
            },
            {
                "coptic": "ϫⲱⲣ ⲉ̀ⲃⲟⲗ ⲛ̀ⲛⲓϫⲁϫⲓ",
                "arabized": "جور إيفول إن ني جاجي",
                "arabic": "فرّق أعداء الكنيسة"
            },
            {
                "coptic": "ⲛ̀ⲧⲉ ϯⲉⲕⲕ̀ⲗⲏⲥⲓⲁ",
                "arabized": "إنتي تي إككليسيا",
                "arabic": "وحصنها فلا تتزعزع"
            }
        ]
    }
]

# Merge avoiding duplicates
existing_ids = {h["id"] for h in hymns}
for add_h in additional_hymns:
    if add_h["id"] not in existing_ids:
        hymns.append(add_h)

with open("assets/data/hymns.json", "w", encoding="utf-8") as f:
    json.dump(hymns, f, ensure_ascii=False, indent=2)

print(f"Total hymns now in library: {len(hymns)}")
