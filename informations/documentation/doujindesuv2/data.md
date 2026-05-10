# DoujinDesu v2 - API Data Examples

**Last Updated**: 2026-05-10  
**Base URL**: https://v2.doujindesu.fun/api

---

## API Endpoints Summary

| Endpoint | Method | Purpose | Pagination |
|----------|--------|---------|-----------|
| `/api/manga-list` | GET | Get paginated manga list | Yes |
| `/api/search` | GET | Search manga | Yes |
| `/api/manga/{slug}` | GET | Get manga detail | No |
| `/api/read/{slug}/{chapter}` | GET | Get chapter content | No |

---

## 1. Manga List API

**Endpoint**: `GET /api/manga-list?limit={limit}&page={page}&q={query}`

### Example 1: Get All Manga (No Filter)
```bash
curl -s "https://v2.doujindesu.fun/api/manga-list?limit=8" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
  -H "Accept: application/json"
```

### Example 2: Get Manga with Search Query
```bash
curl -s "https://v2.doujindesu.fun/api/manga-list?q=ne&limit=8" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
  -H "Accept: application/json"
```

### Response Structure
```json
{
  "success": true,
  "data": [
    {
      "_id": "69fdea77f64532fbd3d04e1b",
      "slug": "new-town-massage",
      "title": "New Town Massage",
      "thumb": "https://cdn-images.doujindesu.fun/covers/new-town-massage.jpg",
      "metadata": {
        "status": "Publishing",
        "type": "Manhwa",
        "series": "Manhwa",
        "author": "Basasak, Secret Service",
        "rating": "8.80",
        "created": "Jumat, 08 Mei 2026"
      },
      "tags": ["Ahegao", "Big Ass", "Big Breast", ...],
      "views": 5843,
      "chapter_count": 8,
      "updatedAt": "2026-05-08T13:51:47.346Z",
      "last_chapter": {
        "title": "8",
        "slug": "new-town-massage-chapter-08",
        "chapter_index": 8,
        "createdAt": "2026-05-08T13:52:34.736Z"
      }
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 117,
    "totalItems": 932,
    "perPage": 8
  }
}
```

---

## 2. Search API

**Endpoint**: `GET /api/search?q={query}`

### Example: Search for "naruto"
```bash
curl -s "https://v2.doujindesu.fun/api/search?q=naruto" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
  -H "Accept: application/json"
```

### Response Structure
```json
{
  "success": true,
  "data": [
    {
      "_id": "69304f990cc971443a671cb8",
      "slug": "narutop-106",
      "title": "NARUTOP 106",
      "thumb": "https://cdn-images.doujindesu.fun/covers/narutop-106.jpg",
      "metadata": {
        "status": "Finished",
        "type": "Doujinshi",
        "series": "Naruto",
        "author": "Sahara Wataru",
        "rating": "7.90",
        "created": "Kamis, 02 Oktober 2025"
      },
      "chapter_count": 1
    },
    {
      "_id": "6950b23967a31c9f38387df0",
      "slug": "narutop-pink",
      "title": "NARUTOP PINK",
      "thumb": "https://cdn-images.doujindesu.fun/covers/narutop-pink.gif",
      "metadata": {
        "status": "Finished",
        "type": "Doujinshi",
        "series": "Naruto",
        "author": "Sahara Wataru",
        "rating": "7.90",
        "created": "Selasa, 22 Oktober 2024"
      },
      "chapter_count": 2
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 1,
    "totalItems": 4,
    "perPage": 24
  }
}
```

---

## 3. Manga Detail API

**Endpoint**: `GET /api/manga/{slug}`

### Example: Get "tsuma-no-imouto" detail
```bash
curl -s "https://v2.doujindesu.fun/api/manga/tsuma-no-imouto" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
  -H "Accept: application/json"
```

### Response Structure
{
    "success": true,
    "data": {
        "info": {
            "_id": "692e8c9f0cc971443a671573",
            "slug": "tsuma-no-imouto",
            "__v": 0,
            "alternativeTitle": "妻の妹, Wife's Younger Sister",
            "createdAt": "2025-12-02T06:52:15.288Z",
            "metadata": {
                "status": "Finished",
                "type": "Doujinshi",
                "series": "Original",
                "author": "",
                "rating": "8.50",
                "created": "Selasa, 22 Juli 2025"
            },
            "synopsis": "",
            "tags": [
                "Big Ass",
                "Big Penis",
                "Bikini",
                "Blackmail",
                "Cheating",
                "Condom",
                "Impregnation",
                "Incest",
                "Inseki",
                "Multi-work Series",
                "Muscle",
                "Nakadashi",
                "Netorare",
                "Paizuri",
                "Pregnant",
                "School Uniform",
                "Sister",
                "Sole Female",
                "Sole Male",
                "Stocking",
                "Swimsuit",
                "Big Breast"
            ],
            "thumb": "https://cdn-images.doujindesu.fun/covers/tsuma-no-imouto.jpg",
            "title": "Tsuma no Imouto",
            "updatedAt": "2026-04-15T15:48:13.093Z",
            "views": 13508,
            "sql_id": 257,
            "chapter_count": 4
        },
        "chapters": [
            {
                "_id": "69dfb3427146a5347d5840c2",
                "slug": "tsuma-no-imouto-4",
                "chapter_index": 4,
                "createdAt": "2026-04-15T15:48:18.016Z",
                "title": "4 END"
            },
            {
                "_id": "692e8ca10cc971443a671574",
                "slug": "tsuma-no-imouto-3",
                "chapter_index": 3,
                "createdAt": "2025-12-02T06:52:17.702Z",
                "title": "3 END"
            },
            {
                "_id": "692e8ca40cc971443a671575",
                "slug": "tsuma-no-imouto-2",
                "chapter_index": 2,
                "createdAt": "2025-12-02T06:52:20.126Z",
                "title": "2"
            },
            {
                "_id": "692e8ca60cc971443a671576",
                "slug": "tsuma-no-imouto",
                "chapter_index": 1,
                "createdAt": "2025-12-02T06:52:22.647Z",
                "title": "1"
            }
        ],
        "recommendations": [
            {
                "_id": "695335d967a31c9f38388e46",
                "slug": "sensei-trale-hossuru-karada",
                "metadata": {
                    "status": "Finished",
                    "type": "Doujinshi",
                    "series": "Original",
                    "author": "Neko Samurai",
                    "rating": "7.60",
                    "created": "Sabtu, 30 Sep 2023"
                },
                "thumb": "https://cdn-images.doujindesu.fun/covers/sensei-trale-hossuru-karada.jpg",
                "title": "Sensei Trale ~Hossuru Karada~",
                "views": 538,
                "chapter_count": 1
            },
            {
                "_id": "694837bb6bee7468fcd3f500",
                "title": "Zeta-chan ni Kyou mo Osowareru",
                "slug": "zetachan-ni-kyou-mo-osowareru",
                "thumb": "https://cdn-images.doujindesu.fun/covers/zetachan-ni-kyou-mo-osowareru.jpg",
                "views": 279,
                "metadata": {
                    "status": "Finished",
                    "type": "Doujinshi",
                    "series": "Blue Archive",
                    "author": "Mr way",
                    "rating": "7.40",
                    "created": "Kamis, 22 Mei 2025"
                },
                "chapter_count": 1
            },
            {
                "_id": "6970f75e69ba8eb94f162424",
                "slug": "oshiego-to-ichinichijuu-sokuhame-shiteiru-dousei-seikatsu",
                "metadata": {
                    "status": "Finished",
                    "type": "Doujinshi",
                    "series": "Original",
                    "author": "Hassen",
                    "rating": "7.40",
                    "created": "Selasa, 21 Juni 2022"
                },
                "thumb": "https://cdn-images.doujindesu.fun/covers/oshiego-to-ichinichijuu-sokuhame-shiteiru-dousei-seikatsu.jpg",
                "title": "Oshiego to Ichinichijuu Sokuhame Shiteiru Dousei Seikatsu",
                "views": 926,
                "chapter_count": 1
            },
            {
                "_id": "695a2d1367a31c9f3838b3da",
                "slug": "class-no-kinpatsu-kyonyuu-gal-to-itya-love-ecchi-suru-hanashi",
                "metadata": {
                    "status": "Finished",
                    "type": "Doujinshi",
                    "series": "Original",
                    "author": "Sueyuu",
                    "rating": "7.70",
                    "created": "Kamis, 15 Juni 2023"
                },
                "thumb": "https://cdn-images.doujindesu.fun/covers/class-no-kinpatsu-kyonyuu-gal-to-itya-love-ecchi-suru-hanashi.jpg",
                "title": "Class no Kinpatsu Kyonyuu Gal to Itya Love Ecchi suru Hanashi",
                "views": 308,
                "chapter_count": 1
            },
            {
                "_id": "696fb93569ba8eb94f160532",
                "slug": "ts-neko-succubus-san-wa-sakusei-nante-shitakunai",
                "metadata": {
                    "status": "Finished",
                    "type": "Doujinshi",
                    "series": "Original",
                    "author": "Uno Ryoku",
                    "rating": "7.00",
                    "created": "Senin, 04 April 2022"
                },
                "thumb": "https://cdn-images.doujindesu.fun/covers/ts-neko-succubus-san-wa-sakusei-nante-shitakunai.jpg",
                "title": "TS Neko Succubus-san wa Sakusei Nante Shitakunai!",
                "views": 491,
                "chapter_count": 1
            },
            {
                "_id": "6964ab7467a31c9f38390b5a",
                "slug": "otaku-ni-yasashii-gyaru-to-gemu-mo-sekkusu-mo-kouryaku-shite-mita",
                "metadata": {
                    "status": "Finished",
                    "type": "Doujinshi",
                    "series": "Original",
                    "author": "Sena Rinko",
                    "rating": "7.20",
                    "created": "Selasa, 13 Sep 2022"
                },
                "thumb": "https://cdn-images.doujindesu.fun/covers/otaku-ni-yasashii-gyaru-to-gemu-mo-sekkusu-mo-kouryaku-shite-mita.jpg",
                "title": "Otaku ni Yasashii Gyaru to Gemu mo Sekkusu mo Kouryaku Shite Mita",
                "views": 134,
                "chapter_count": 1
            }
        ]
    },
    "pagination": null
}

https://v2.doujindesu.fun/api/read/tsuma-no-imouto/tsuma-no-imouto
untuk reader nya

{
    "success": true,
    "data": {
        "chapter": {
            "_id": "692e8ca60cc971443a671576",
            "manga_id": "692e8c9f0cc971443a671573",
            "slug": "tsuma-no-imouto",
            "__v": 2,
            "chapter_index": 1,
            "createdAt": "2025-12-02T06:52:22.647Z",
            "images": [
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (1).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (2).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (3).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (4).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (5).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (6).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (7).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (8).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (9).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (10).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (11).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (12).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (13).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (14).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (15).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (16).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (17).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (18).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (19).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (20).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (21).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (22).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (23).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (24).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (25).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (26).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (27).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (28).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (29).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (30).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (31).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (32).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (33).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (34).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (35).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (36).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (37).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (38).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (39).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (40).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (41).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (42).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (43).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (44).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (45).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (46).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (47).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (48).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (49).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (50).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (51).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (52).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (53).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (54).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (55).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (56).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (57).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (58).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (59).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (60).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (61).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (62).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (63).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (64).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (65).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (66).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (67).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (68).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (69).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (70).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (71).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (72).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (73).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (74).webp",
                "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (75).webp"
            ],
            "link": "https://doujindesu.tv/tsuma-no-imouto/",
            "title": "1",
            "updatedAt": "2025-12-27T19:41:44.694Z",
            "sql_id": 774
        },
        "manga": {
            "_id": "692e8c9f0cc971443a671573",
            "slug": "tsuma-no-imouto",
            "thumb": "https://cdn-images.doujindesu.fun/covers/tsuma-no-imouto.jpg",
            "title": "Tsuma no Imouto"
        },
        "navigation": {
            "next": "tsuma-no-imouto-2",
            "prev": null
        }
    },
    "pagination": null
}