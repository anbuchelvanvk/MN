import 'health_models.dart';

/// Tamil Nadu and wider Indian dishes with approximate calories per 100 g
/// (home-style recipes; values follow common Indian food-composition tables).
/// Names carry the Tamil name so people can search either way.
FoodItem _f(String id, String name, String cat, double kcal, double grams, String unit, [String emoji = '🍽️']) =>
    FoodItem(
      id: 'ta_$id',
      name: name,
      category: cat,
      caloriesPer100g: kcal,
      defaultServingGrams: grams,
      servingUnit: unit,
      iconEmoji: emoji,
    );

const _b = 'Breakfast';
const _m = 'Main Course';
const _c = 'Lentils & Curries';
const _d = 'Dairy & Sides';
const _s = 'Snacks & Beverages';
const _h = 'Fruits & Healthy';

final List<FoodItem> tamilIndianFoods = [
  // ------------------------------------------------------------- tiffin
  _f('idli', 'Idli (இட்லி)', _b, 130, 80, '2 idlis (~80g)', '🍚'),
  _f('rava_idli', 'Rava Idli (ரவா இட்லி)', _b, 150, 120, '2 pieces (~120g)', '🍚'),
  _f('kanchi_idli', 'Kanchipuram Idli (காஞ்சிபுரம் இட்லி)', _b, 175, 100, '2 pieces (~100g)', '🍚'),
  _f('podi_idli', 'Podi Idli with Ghee (பொடி இட்லி)', _b, 195, 120, '6 mini idlis (~120g)', '🍚'),
  _f('sambar_idli', 'Sambar Idli (சாம்பார் இட்லி)', _b, 115, 220, '2 idlis in sambar (~220g)', '🍲'),
  _f('kal_dosai', 'Kal Dosai (கல் தோசை)', _b, 170, 160, '2 soft dosais (~160g)', '🥞'),
  _f('set_dosa', 'Set Dosa (செட் தோசை)', _b, 175, 150, '3 pieces (~150g)', '🥞'),
  _f('paper_roast', 'Paper Roast Dosa (பேப்பர் ரோஸ்ட்)', _b, 205, 110, '1 large (~110g)', '🥞'),
  _f('podi_dosa', 'Podi Dosa (பொடி தோசை)', _b, 215, 110, '1 dosa (~110g)', '🥞'),
  _f('egg_dosa', 'Egg Dosa (முட்டை தோசை)', _b, 190, 140, '1 dosa (~140g)', '🥚'),
  _f('ragi_dosa', 'Ragi Dosa (கேழ்வரகு தோசை)', _b, 140, 100, '1 dosa (~100g)', '🥞'),
  _f('wheat_dosa', 'Wheat Dosa (கோதுமை தோசை)', _b, 155, 100, '1 dosa (~100g)', '🥞'),
  _f('adai', 'Adai (அடை)', _b, 190, 110, '1 adai (~110g)', '🥞'),
  _f('pesarattu', 'Pesarattu / Moong Dosa', _b, 160, 110, '1 dosa (~110g)', '🥞'),
  _f('tomato_uthappam', 'Tomato Uthappam (தக்காளி ஊத்தப்பம்)', _b, 165, 130, '1 uthappam (~130g)', '🥞'),
  _f('paniyaram', 'Kuzhi Paniyaram (குழி பணியாரம்)', _b, 200, 100, '5 pieces (~100g)', '🧆'),
  _f('sweet_paniyaram', 'Sweet Paniyaram (இனிப்பு பணியாரம்)', _b, 265, 90, '4 pieces (~90g)', '🧆'),
  _f('lemon_sevai', 'Lemon Sevai (எலுமிச்சை சேவை)', _b, 150, 180, '1 plate (~180g)', '🍜'),
  _f('kothu_parotta', 'Veg Kothu Parotta (கொத்து பரோட்டா)', _b, 220, 250, '1 plate (~250g)', '🫓'),
  _f('chicken_kothu', 'Chicken Kothu Parotta (சிக்கன் கொத்து)', _b, 235, 280, '1 plate (~280g)', '🫓'),
  _f('egg_kothu', 'Egg Kothu Parotta (முட்டை கொத்து)', _b, 225, 260, '1 plate (~260g)', '🫓'),
  _f('veechu_parotta', 'Veechu Parotta (வீச்சு பரோட்டா)', _b, 320, 90, '1 piece (~90g)', '🫓'),
  _f('ragi_koozh', 'Ragi Koozh (கேழ்வரகு கூழ்)', _b, 60, 250, '1 glass (~250ml)', '🥣'),
  _f('kambu_koozh', 'Kambu Koozh (கம்பு கூழ்)', _b, 65, 250, '1 glass (~250ml)', '🥣'),
  _f('ragi_kali', 'Ragi Kali (கேழ்வரகு களி)', _b, 130, 150, '1 ball (~150g)', '🥣'),
  _f('semiya_upma', 'Semiya Upma (சேமியா உப்புமா)', _b, 160, 180, '1 plate (~180g)', '🍜'),
  _f('godhumai_upma', 'Godhumai Rava Upma (கோதுமை ரவை)', _b, 150, 180, '1 plate (~180g)', '🥣'),
  _f('kichadi', 'Rava Kichadi (ரவா கிச்சடி)', _b, 165, 180, '1 plate (~180g)', '🥣'),
  _f('kozhukattai', 'Kozhukattai (கொழுக்கட்டை)', _b, 185, 100, '3 pieces (~100g)', '🥟'),
  _f('sweet_kozhukattai', 'Sweet Kozhukattai / Modak (இனிப்பு கொழுக்கட்டை)', _b, 230, 90, '3 pieces (~90g)', '🥟'),
  _f('aappam_stew', 'Appam with Vegetable Stew (ஆப்பம்)', _b, 140, 230, '2 appams + stew (~230g)', '🥞'),
  _f('idiyappam_paal', 'Idiyappam with Coconut Milk (இடியாப்பம்)', _b, 160, 180, '3 pieces + milk (~180g)', '🍜'),
  _f('puttu_kadala', 'Puttu with Kadala Curry (புட்டு)', _b, 175, 250, '1 serving (~250g)', '🍚'),
  _f('bread_toast', 'Bread Toast with Butter', _b, 300, 60, '2 slices (~60g)', '🍞'),

  // -------------------------------------------------------------- rice
  _f('puliyodharai', 'Puliyodharai / Tamarind Rice (புளியோதரை)', _m, 190, 200, '1 plate (~200g)', '🍚'),
  _f('coconut_rice', 'Coconut Rice (தேங்காய் சாதம்)', _m, 210, 200, '1 plate (~200g)', '🍚'),
  _f('pudina_rice', 'Mint Rice (புதினா சாதம்)', _m, 175, 200, '1 plate (~200g)', '🍚'),
  _f('rasam_rice', 'Rasam Rice (ரசம் சாதம்)', _m, 105, 250, '1 plate (~250g)', '🍚'),
  _f('kara_kuzhambu_rice', 'Kara Kuzhambu Sadam (காரக்குழம்பு சாதம்)', _m, 135, 250, '1 plate (~250g)', '🍚'),
  _f('paruppu_sadam', 'Paruppu Sadam with Ghee (பருப்பு சாதம்)', _m, 150, 250, '1 plate (~250g)', '🍚'),
  _f('kuska', 'Kuska / Plain Biryani (குஸ்கா)', _m, 190, 250, '1 plate (~250g)', '🍛'),
  _f('dindigul_biryani', 'Dindigul Chicken Biryani (திண்டுக்கல் பிரியாணி)', _m, 200, 300, '1 plate (~300g)', '🍛'),
  _f('ambur_biryani', 'Ambur Mutton Biryani (ஆம்பூர் பிரியாணி)', _m, 215, 300, '1 plate (~300g)', '🍛'),
  _f('prawn_biryani', 'Prawn Biryani (இறால் பிரியாணி)', _m, 185, 300, '1 plate (~300g)', '🍛'),
  _f('fish_biryani', 'Fish Biryani (மீன் பிரியாணி)', _m, 180, 300, '1 plate (~300g)', '🍛'),
  _f('mushroom_biryani', 'Mushroom Biryani (காளான் பிரியாணி)', _m, 165, 300, '1 plate (~300g)', '🍛'),
  _f('brinjal_rice', 'Vangi Bath / Brinjal Rice (கத்திரிக்காய் சாதம்)', _m, 175, 200, '1 plate (~200g)', '🍚'),
  _f('meals_nonveg', 'Non-Veg Meals (சாப்பாடு with Chicken)', _m, 150, 550, '1 full meal (~550g)', '🍱'),
  _f('meals_mini', 'Mini Meals (மினி சாப்பாடு)', _m, 140, 400, '1 mini meal (~400g)', '🍱'),

  // ------------------------------------------------- kuzhambu & curries
  _f('vatha_kuzhambu', 'Vatha Kuzhambu (வத்தக் குழம்பு)', _c, 120, 100, '1 small bowl (~100g)', '🍲'),
  _f('kara_kuzhambu', 'Kara Kuzhambu (காரக் குழம்பு)', _c, 110, 120, '1 bowl (~120g)', '🍲'),
  _f('mor_kuzhambu', 'Mor Kuzhambu (மோர் குழம்பு)', _c, 80, 150, '1 bowl (~150g)', '🍲'),
  _f('puli_kuzhambu', 'Puli Kuzhambu (புளிக் குழம்பு)', _c, 100, 120, '1 bowl (~120g)', '🍲'),
  _f('ennai_kathirikai', 'Ennai Kathirikai (எண்ணெய் கத்திரிக்காய்)', _c, 150, 120, '1 bowl (~120g)', '🍆'),
  _f('meen_kuzhambu', 'Meen Kuzhambu / Fish Curry (மீன் குழம்பு)', _c, 120, 150, '1 bowl with fish (~150g)', '🐟'),
  _f('nattu_kozhi', 'Nattu Kozhi Kuzhambu (நாட்டுக்கோழி குழம்பு)', _c, 140, 150, '1 bowl (~150g)', '🍗'),
  _f('chicken_kuzhambu', 'Chicken Kuzhambu (சிக்கன் குழம்பு)', _c, 145, 150, '1 bowl (~150g)', '🍗'),
  _f('mutton_kuzhambu', 'Mutton Kuzhambu (மட்டன் குழம்பு)', _c, 165, 150, '1 bowl (~150g)', '🍖'),
  _f('egg_kuzhambu', 'Egg Kuzhambu (முட்டை குழம்பு)', _c, 135, 180, '2 eggs in gravy (~180g)', '🥚'),
  _f('paruppu', 'Paruppu / Tamil Dal (பருப்பு)', _c, 120, 150, '1 bowl (~150g)', '🥣'),
  _f('kootu', 'Kootu - Chow Chow / Cabbage (கூட்டு)', _c, 90, 150, '1 bowl (~150g)', '🥬'),
  _f('avial', 'Avial (அவியல்)', _c, 110, 150, '1 bowl (~150g)', '🥕'),
  _f('beans_poriyal', 'Beans Poriyal (பீன்ஸ் பொரியல்)', _c, 95, 100, '1 bowl (~100g)', '🫛'),
  _f('cabbage_poriyal', 'Cabbage Poriyal (முட்டைக்கோஸ் பொரியல்)', _c, 85, 100, '1 bowl (~100g)', '🥬'),
  _f('carrot_poriyal', 'Carrot Poriyal (கேரட் பொரியல்)', _c, 90, 100, '1 bowl (~100g)', '🥕'),
  _f('beetroot_poriyal', 'Beetroot Poriyal (பீட்ரூட் பொரியல்)', _c, 90, 100, '1 bowl (~100g)', '🥗'),
  _f('vazhakkai', 'Vazhakkai Fry (வாழைக்காய் வறுவல்)', _c, 150, 100, '1 bowl (~100g)', '🍌'),
  _f('urulai_roast', 'Urulaikizhangu Roast (உருளைக்கிழங்கு வறுவல்)', _c, 165, 100, '1 bowl (~100g)', '🥔'),
  _f('keerai_masiyal', 'Keerai Masiyal (கீரை மசியல்)', _c, 70, 120, '1 bowl (~120g)', '🥬'),
  _f('vendakkai_poriyal', 'Vendakkai Fry (வெண்டைக்காய் பொரியல்)', _c, 130, 100, '1 bowl (~100g)', '🫛'),
  _f('mysore_rasam', 'Mysore Rasam (மைசூர் ரசம்)', _c, 50, 150, '1 bowl (~150ml)', '🍵'),
  _f('thayir_pachadi', 'Thayir Pachadi (தயிர் பச்சடி)', _d, 70, 100, '1 bowl (~100g)', '🥣'),
  _f('veg_salna', 'Salna for Parotta (சால்னா)', _c, 120, 150, '1 bowl (~150g)', '🍲'),
  _f('chicken_salna', 'Chicken Salna (சிக்கன் சால்னா)', _c, 140, 150, '1 bowl (~150g)', '🍗'),
  _f('pepper_chicken', 'Pepper Chicken (மிளகு சிக்கன்)', _c, 210, 150, '1 bowl (~150g)', '🍗'),
  _f('chicken_65', 'Chicken 65 (சிக்கன் 65)', _c, 265, 120, '1 plate (~120g)', '🍗'),
  _f('chicken_varuval', 'Chicken Varuval / Chukka (சிக்கன் வறுவல்)', _c, 230, 120, '1 plate (~120g)', '🍗'),
  _f('mutton_chukka', 'Mutton Sukka (மட்டன் சுக்கா)', _c, 250, 120, '1 plate (~120g)', '🍖'),
  _f('kola_urundai', 'Mutton Kola Urundai (கோலா உருண்டை)', _c, 275, 80, '4 pieces (~80g)', '🧆'),
  _f('nethili_fry', 'Nethili Fish Fry (நெத்திலி வறுவல்)', _c, 245, 100, '1 plate (~100g)', '🐟'),
  _f('vanjaram_fry', 'Vanjaram Fish Fry (வஞ்சிரம் வறுவல்)', _c, 210, 100, '1 slice (~100g)', '🐟'),
  _f('eral_thokku', 'Prawn Thokku (இறால் தொக்கு)', _c, 180, 120, '1 bowl (~120g)', '🦐'),
  _f('nandu_masala', 'Crab Masala (நண்டு மசாலா)', _c, 150, 150, '1 bowl (~150g)', '🦀'),
  _f('egg_podimas', 'Egg Podimas (முட்டை பொடிமாஸ்)', _c, 185, 100, '2 eggs (~100g)', '🥚'),
  _f('kaadai_fry', 'Kaadai / Quail Fry (காடை வறுவல்)', _c, 230, 100, '1 bird (~100g)', '🍗'),
  _f('paneer_tikka', 'Paneer Tikka', _c, 265, 120, '6 pieces (~120g)', '🧀'),
  _f('mushroom_masala', 'Mushroom Masala (காளான் மசாலா)', _c, 115, 150, '1 bowl (~150g)', '🍄'),
  _f('gobi_65', 'Gobi 65 / Cauliflower Fry (காலிஃபிளவர் 65)', _s, 240, 100, '1 plate (~100g)', '🥦'),

  // ------------------------------------------------------ snacks & sweets
  _f('paruppu_vadai', 'Paruppu Vadai / Masala Vadai (பருப்பு வடை)', _s, 320, 50, '1 vadai (~50g)', '🧆'),
  _f('keerai_vadai', 'Keerai Vadai (கீரை வடை)', _s, 300, 50, '1 vadai (~50g)', '🧆'),
  _f('thayir_vadai', 'Thayir Vadai / Curd Vada (தயிர் வடை)', _s, 190, 120, '2 vadai in curd (~120g)', '🧆'),
  _f('sambar_vadai', 'Sambar Vadai (சாம்பார் வடை)', _s, 170, 150, '2 vadai in sambar (~150g)', '🧆'),
  _f('aloo_bonda', 'Aloo Bonda (போண்டா)', _s, 280, 60, '1 bonda (~60g)', '🥔'),
  _f('vazhakkai_bajji', 'Vazhakkai Bajji (வாழைக்காய் பஜ்ஜி)', _s, 280, 60, '2 pieces (~60g)', '🍌'),
  _f('murukku', 'Murukku (முறுக்கு)', _s, 520, 30, '1 murukku (~30g)', '🥨'),
  _f('thattai', 'Thattai (தட்டை)', _s, 500, 25, '2 pieces (~25g)', '🍘'),
  _f('mixture', 'Madras Mixture (மிக்சர்)', _s, 540, 30, '1 small cup (~30g)', '🥜'),
  _f('ribbon_pakoda', 'Ribbon Pakoda (ரிப்பன் பக்கோடா)', _s, 520, 30, '1 small cup (~30g)', '🥨'),
  _f('seedai', 'Seedai (சீடை)', _s, 480, 30, '10 pieces (~30g)', '🟤'),
  _f('kadalai_mittai', 'Kadalai Mittai / Peanut Chikki (கடலை மிட்டாய்)', _s, 500, 25, '1 bar (~25g)', '🥜'),
  _f('egg_puffs', 'Egg Puffs (முட்டை பஃப்ஸ்)', _s, 300, 90, '1 puff (~90g)', '🥐'),
  _f('veg_puffs', 'Veg Puffs (வெஜ் பஃப்ஸ்)', _s, 290, 80, '1 puff (~80g)', '🥐'),
  _f('adhirasam', 'Adhirasam (அதிரசம்)', _s, 400, 50, '1 piece (~50g)', '🍪'),
  _f('mysore_pak', 'Mysore Pak (மைசூர் பாக்)', _s, 520, 40, '1 piece (~40g)', '🍬'),
  _f('boondi_laddu', 'Boondi Laddu (லட்டு)', _s, 430, 40, '1 laddu (~40g)', '🟠'),
  _f('rava_laddu', 'Rava Laddu (ரவா லட்டு)', _s, 450, 35, '1 laddu (~35g)', '🟡'),
  _f('rava_kesari', 'Rava Kesari (ரவா கேசரி)', _s, 340, 80, '1 small bowl (~80g)', '🟧'),
  _f('sakkarai_pongal', 'Sakkarai Pongal (சர்க்கரைப் பொங்கல்)', _s, 260, 150, '1 bowl (~150g)', '🍯'),
  _f('semiya_payasam', 'Semiya Payasam (சேமியா பாயசம்)', _s, 160, 150, '1 bowl (~150ml)', '🍮'),
  _f('paal_payasam', 'Paal Payasam (பால் பாயசம்)', _s, 170, 150, '1 bowl (~150ml)', '🍮'),
  _f('halwa', 'Tirunelveli Halwa (திருநெல்வேலி அல்வா)', _s, 430, 50, '1 piece (~50g)', '🍬'),
  _f('carrot_halwa', 'Carrot Halwa / Gajar Halwa', _s, 280, 80, '1 small bowl (~80g)', '🥕'),
  _f('dhokla', 'Dhokla', _s, 160, 100, '4 pieces (~100g)', '🟨'),
  _f('aloo_tikki', 'Aloo Tikki', _s, 220, 80, '2 tikkis (~80g)', '🥔'),
  _f('kachori', 'Kachori', _s, 410, 60, '1 kachori (~60g)', '🥟'),

  // ------------------------------------------------------------- drinks
  _f('sukku_coffee', 'Sukku Malli Coffee (சுக்கு மல்லி காபி)', _s, 40, 150, '1 cup (~150ml)', '☕'),
  _f('health_drink', 'Boost / Horlicks with Milk', _s, 85, 200, '1 glass (~200ml)', '🥛'),
  _f('ragi_malt', 'Ragi Malt (கேழ்வரகு கஞ்சி)', _s, 80, 200, '1 glass (~200ml)', '🥛'),
  _f('badam_milk', 'Badam Milk (பாதாம் பால்)', _s, 120, 200, '1 glass (~200ml)', '🥛'),
  _f('rose_milk', 'Rose Milk (ரோஸ் மில்க்)', _s, 95, 250, '1 glass (~250ml)', '🌹'),
  _f('jigarthanda', 'Jigarthanda (ஜிகர்தண்டா)', _s, 180, 250, '1 glass (~250ml)', '🥤'),
  _f('nannari', 'Nannari Sarbath (நன்னாரி சர்பத்)', _s, 60, 250, '1 glass (~250ml)', '🥤'),
  _f('paneer_soda', 'Goli Soda / Paneer Soda (கோலி சோடா)', _s, 40, 200, '1 bottle (~200ml)', '🥤'),
  _f('kanji', 'Rice Kanji (அரிசி கஞ்சி)', _s, 50, 250, '1 bowl (~250ml)', '🥣'),
  _f('sugarcane', 'Sugarcane Juice (கரும்புச் சாறு)', _s, 70, 250, '1 glass (~250ml)', '🥤'),

  // ------------------------------------------------------------- fruits
  _f('sapota', 'Sapota / Chikoo (சப்போட்டா)', _h, 83, 100, '1 fruit (~100g)', '🟤'),
  _f('jackfruit', 'Jackfruit (பலாப்பழம்)', _h, 95, 100, '5 pods (~100g)', '🟡'),
  _f('custard_apple', 'Custard Apple (சீதாப்பழம்)', _h, 94, 120, '1 fruit (~120g)', '🍏'),
  _f('nungu', 'Nungu / Ice Apple (நுங்கு)', _h, 43, 100, '3 pieces (~100g)', '🥥'),
  _f('nendran', 'Nendran Banana (நேந்திரம் பழம்)', _h, 120, 120, '1 banana (~120g)', '🍌'),
  _f('amla', 'Amla / Gooseberry (நெல்லிக்காய்)', _h, 44, 50, '2 pieces (~50g)', '🟢'),
  _f('dates', 'Dates (பேரீச்சம்பழம்)', _h, 280, 30, '3 dates (~30g)', '🟤'),
  _f('sprouts_salad', 'Mulaikattiya Payaru / Sprouts (முளைகட்டிய பயறு)', _h, 105, 100, '1 bowl (~100g)', '🥗'),
];

/// Local spellings people type, mapped to one word so search finds them.
const Map<String, String> foodSearchAliases = {
  'idly': 'idli', 'itli': 'idli', 'iddli': 'idli',
  'dosai': 'dosa', 'thosai': 'dosa', 'dose': 'dosa', 'thosa': 'dosa',
  'sadam': 'rice', 'satham': 'rice', 'saadham': 'rice', 'sadham': 'rice', 'soru': 'rice', 'annam': 'rice',
  'kulambu': 'kuzhambu', 'kozhambu': 'kuzhambu', 'kuzhambhu': 'kuzhambu', 'kolambu': 'kuzhambu',
  'parota': 'parotta', 'porotta': 'parotta', 'barotta': 'parotta', 'paratta': 'parotta',
  'vada': 'vadai', 'vadey': 'vadai', 'vade': 'vadai',
  'biriyani': 'biryani', 'briyani': 'biryani', 'biriani': 'biryani',
  'chappathi': 'chapati', 'chappati': 'chapati', 'chapathi': 'chapati', 'roti': 'chapati',
  'kheer': 'payasam', 'payasa': 'payasam',
  'kozhi': 'chicken', 'koli': 'chicken',
  'meen': 'fish', 'muttai': 'egg', 'mutta': 'egg', 'eral': 'prawn', 'iral': 'prawn', 'nandu': 'crab',
  'aatu': 'mutton', 'attu': 'mutton', 'goat': 'mutton',
  'spinach': 'keerai', 'greens': 'keerai',
  'kaapi': 'coffee', 'kapi': 'coffee', 'chai': 'tea', 'tee': 'tea',
  'kool': 'koozh', 'kooz': 'koozh', 'kelvaragu': 'ragi', 'kezhvaragu': 'ragi', 'finger': 'ragi',
  'pongali': 'pongal', 'upuma': 'upma', 'uppuma': 'upma',
  'thayir': 'curd', 'tayir': 'curd', 'dahi': 'curd', 'yogurt': 'curd',
  'mor': 'buttermilk', 'chaas': 'buttermilk',
  'paal': 'milk', 'vazhaipazham': 'banana', 'pazham': 'fruit',
  'poriyal': 'poriyal', 'thoran': 'poriyal', 'varuval': 'fry', 'varuvel': 'fry',
  'bajji': 'bajji', 'bhajji': 'bajji', 'bhaji': 'bajji',
  'paniyaram': 'paniyaram', 'paniaram': 'paniyaram', 'kuzhipaniyaram': 'paniyaram',
  'idiappam': 'idiyappam', 'idiyapam': 'idiyappam', 'sevai': 'idiyappam',
};

String normaliseFoodText(String s) {
  final words = s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9஀-௿ ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => foodSearchAliases[w] ?? w);
  return words.join(' ');
}
