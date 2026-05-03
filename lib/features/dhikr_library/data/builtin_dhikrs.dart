import '../domain/dhikr_item.dart';

const builtinDhikrs = [
  DhikrItem(
    id: 'subhanallah',
    name: 'Sübhanallah',
    arabicText: 'سبحان الله',
    meaning: 'Allah her türlü eksiklikten uzaktır.',
    longMeaning:
        'Kalbin Rabbine duyduğu hayretin ilk sözüdür. Mümin, kâinatın her zerresinde O’nun kudretini görür ve “Rabbim her türlü eksiklikten münezzehtir” der. Dile hafif, mizanda ağır olan bu kelime, gönüldeki tevhid nuruna tercüman olur.',
    category: 'Tesbih',
    defaultTarget: 33,
  ),
  DhikrItem(
    id: 'elhamdulillah',
    name: 'Elhamdülillah',
    arabicText: 'الحمد لله',
    meaning: 'Hamd ve şükür yalnız Allah içindir.',
    longMeaning:
        'Nimetin sahibini unutmayan kalbin şükrüdür. Mümin, sevinçte de imtihanda da hamdin yalnız âlemlerin Rabbi Allah’a ait olduğunu bilir. Bu söz, verilen her nefesi emanet görmeye; kalbi rızaya, şükre ve teslimiyete çağırır.',
    category: 'Tesbih',
    defaultTarget: 33,
  ),
  DhikrItem(
    id: 'allahu-ekber',
    name: 'Allahu ekber',
    arabicText: 'الله أكبر',
    meaning: 'Allah en büyüktür.',
    longMeaning:
        'Kalbin bütün büyüttüklerini geride bırakıp Rabbini yüceltmesidir. Mümin bu sözle korkuların, arzuların ve dünyanın geçici ağırlığının üstünde Allah’ın azametini hatırlar. Tekbir, kulun yönünü toparlar; kalbe vakar, namaza ve zikre derinlik verir.',
    category: 'Tesbih',
    defaultTarget: 33,
  ),
  DhikrItem(
    id: 'estagfirullah',
    name: 'Estağfirullah',
    arabicText: 'أستغفر الله',
    meaning: 'Allah’tan bağışlanma dilerim.',
    longMeaning:
        'İstiğfarın en kısa ve en yalın kapısıdır. Kul bu sözle kusurunu örtmez; Rabbine açar, bağışlanmayı yalnız O’ndan ister. Farz namazların ardından istiğfarın sünnet oluşunu hatırlatan bu kelime, kalbi arındırır ve yeniden Allah’a yönelişin sessiz başlangıcı olur.',
    category: 'İstiğfar',
    defaultTarget: 100,
  ),
  DhikrItem(
    id: 'estagfirullah-el-azim',
    name:
        'Estağfirullahe’l-azîm ellezî lâ ilâhe illâ hüve’l-Hayyü’l-Kayyûm ve etûbü ileyh',
    arabicText:
        'أَسْتَغْفِرُ اللّٰهَ الْعَظِيمَ الَّذِي لَا إِلٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
    meaning:
        'Kendisinden başka ilah olmayan, Hayy ve Kayyûm olan yüce Allah’tan bağışlanma diler ve O’na tövbe ederim.',
    longMeaning:
        'Bu istiğfar, mağfiret dileğini tevhid ve Allah’ın Hayy ve Kayyûm isimleriyle birleştirir. Kul, yüce Rabbinden bağışlanma isterken hayatı ve varlığı ayakta tutanın yalnız O olduğunu ikrar eder; tövbesini daha derin bir teslimiyetle O’na arz eder.',
    category: 'İstiğfar',
    defaultTarget: 3,
  ),
  DhikrItem(
    id: 'seyyidul-istigfar',
    name: "Seyyidü'l-istiğfar",
    arabicText:
        'اللهم أنت ربي لا إله إلا أنت خلقتني وأنا عبدك وأنا على عهدك ووعدك ما استطعت أعوذ بك من شر ما صنعت أبوء لك بنعمتك علي وأبوء لك بذنبي فاغفر لي فإنه لا يغفر الذنوب إلا أنت',
    meaning:
        'Allah’ım! Sen benim Rabbimsin. Beni bağışla; günahları Senden başka bağışlayacak yoktur.',
    longMeaning:
        'Hz. Peygamber’in “istiğfarın en güzeli” olarak bildirdiği duadır. Kul bu duada Allah’ın rabliğini, kendi kulluğunu, nimetleri ve günahını itiraf ederek mağfiret ister.',
    category: 'İstiğfar',
    defaultTarget: 1,
  ),
  DhikrItem(
    id: 'rabbigfir-li-ve-tub-aleyye',
    name: 'Rabbiğfir lî ve tüb aleyye, inneke ente’t-Tevvâbü’r-Rahîm',
    arabicText:
        'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
    meaning:
        'Rabbim, beni bağışla ve tövbemi kabul et. Şüphesiz Sen tövbeleri çok kabul eden, çok merhamet edensin.',
    longMeaning:
        'Hz. Peygamber’in meclislerinde çokça tekrar ettiği rivayet edilen bu dua, mağfiret ile tövbeyi bir araya getirir. Kul, yalnız bağışlanmayı değil, tövbesinin kabulünü de ister; Allah’ın Tevvâb ve Rahîm isimlerine sığınarak kalbini umutla toparlar.',
    category: 'İstiğfar',
    defaultTarget: 100,
  ),
  DhikrItem(
    id: 'subhanallahi-bihamdihi-estagfirullah',
    name: 'Sübhanallahi ve bihamdihî, estağfirullahe ve etûbü ileyh',
    arabicText:
        'سُبْحَانَ اللهِ وَبِحَمْدِهِ أَسْتَغْفِرُ اللهَ وَأَتُوبُ إِلَيْهِ',
    meaning:
        'Allah’ı hamd ile tesbih eder, Allah’tan bağışlanma diler ve O’na tövbe ederim.',
    longMeaning:
        'Hamd ile tesbihin ardından gelen istiğfar, kulun Rabbini yüceltirken kendi eksikliğini unutmamasıdır. Kur’an’da hamd ile tesbih edip bağışlanma dileme emredilir; bu zikir de kalbi hem şükre hem tevazua çağıran dengeli bir dönüş duasıdır.',
    category: 'İstiğfar',
    defaultTarget: 1,
  ),
  DhikrItem(
    id: 'allahumme-inneke-afuvvun',
    name: 'Allahümme inneke afüvvün tühibbü’l-afve fa‘fü annî',
    arabicText: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
    meaning: 'Allah’ım! Sen affedicisin, affetmeyi seversin; beni de affet.',
    longMeaning:
        'Affı seven Rabb’e en mahrem niyazlardan biridir. Kul burada yalnız günahının örtülmesini değil, izinin de silinmesini ister. Hz. Âişe’ye öğretilen bu dua, özellikle Kadir gecesinin ruhuna yakışan bir teslimiyet ve arınma dileğidir.',
    category: 'İstiğfar',
    defaultTarget: 1,
  ),
  DhikrItem(
    id: 'rabbena-zalemna',
    name:
        'Rabbenâ zalemnâ enfüsenâ ve in lem tağfir lenâ ve terhamnâ lenekûnenne mine’l-hâsirîn',
    arabicText:
        'رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
    meaning:
        'Rabbimiz! Biz kendimize zulmettik. Eğer bizi bağışlamaz ve bize merhamet etmezsen mutlaka ziyan edenlerden oluruz.',
    longMeaning:
        'Hz. Âdem ile Havvâ’nın tövbe dilidir. Kul bu duada suçu başkasına yüklemez; önce kendi nefsine baktığını, mağfiret ve rahmet olmadan kurtuluş bulamayacağını itiraf eder. Bu söz, pişmanlığı rahmet kapısına götüren derin bir yakarıştır.',
    category: 'İstiğfar',
    defaultTarget: 1,
  ),
  DhikrItem(
    id: 'la-ilahe-illallah',
    name: 'Lâ ilâhe illallah',
    arabicText: 'لا إله إلا الله',
    meaning: 'Allah’tan başka ilah yoktur.',
    longMeaning:
        'Kelime-i tevhidin en sade ve en derin ifadesidir. Kul bu sözle kalbinde Allah’tan başka hiçbir mabuda yer bırakmaz; yönelişini, ümidini ve kulluğunu yalnız O’na bağlar. Bu zikir, imanın merkezini diri tutan berrak bir şahitliktir.',
    category: 'Tevhid',
    defaultTarget: 100,
  ),
  DhikrItem(
    id: 'la-ilahe-illallah-vahdehu',
    name:
        'Lâ ilâhe illallahü vahdehû lâ şerîke leh, lehü’l-mülkü ve lehü’l-hamdü ve hüve alâ külli şey’in kadîr',
    arabicText:
        'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    meaning:
        'Allah’tan başka ilah yoktur. O tektir, ortağı yoktur. Mülk O’nundur, hamd O’nadır; O’nun her şeye gücü yeter.',
    longMeaning:
        'Tevhidin kalpte kök salan özüdür. Kul bu sözle bütün sığınakları, güç iddialarını ve sahte ilahları geride bırakır; mülkün, hamdin ve kudretin yalnız Allah’a ait olduğunu ikrar eder. Bu zikir, imanı toparlayan ve kalbi kulluğun merkezine döndüren en büyük şahitliktir.',
    category: 'Tevhid',
    defaultTarget: 100,
  ),
  DhikrItem(
    id: 'la-havle',
    name: 'Lâ havle ve lâ kuvvete illâ billâh',
    arabicText: 'لا حول ولا قوة إلا بالله',
    meaning: 'Güç ve kuvvet ancak Allah’ın yardımıyladır.',
    longMeaning:
        'Kulun kendi aczini incitmeden kabul ettiği teslimiyet sözüdür. İnsan, değişmeye ve dayanabilmeye ancak Allah’ın yardımıyla güç bulduğunu hatırlar. Hadiste cennet hazinelerinden biri olarak bildirilen bu zikir, kalbi telaştan alıp tevekkülün serinliğine taşır.',
    category: 'Tevhid',
    defaultTarget: 100,
  ),
  DhikrItem(
    id: 'subhanallahi-ve-bihamdihi',
    name: 'Sübhanallahi ve bihamdihî',
    arabicText: 'سبحان الله وبحمده',
    meaning: 'Allah’ı hamd ile tesbih ederim.',
    longMeaning:
        'Tesbih ile hamdi bir araya getiren bereketli bir zikirdir. Kul, Rabbini eksiklikten tenzih ederken aynı anda O’na hamd eder; kusurunu değil, Rabbinin lütfunu görür. Hadislerde fazileti bildirilen bu söz, dili arındırır ve kalbi şükürle yumuşatır.',
    category: 'Tesbih',
    defaultTarget: 100,
  ),
  DhikrItem(
    id: 'subhanallahi-bihamdihi-adede-halkihi',
    name:
        'Sübhanallahi ve bihamdihî adede halkıhî ve rıdâ nefsihî ve zinete arşihî ve midâde kelimâtih',
    arabicText:
        'سُبْحَانَ اللهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ وَرِضَا نَفْسِهِ وَزِنَةَ عَرْشِهِ وَمِدَادَ كَلِمَاتِهِ',
    meaning:
        'Allah’ı; yarattıklarının sayısınca, rızasına uygun, arşının ağırlığınca ve kelimelerinin genişliğince hamd ile tesbih ederim.',
    longMeaning:
        'Hz. Peygamber’in Cüveyriye validemize öğrettiği, az sözle geniş mânayı kuşatan bir tesbihtir. Kul bu zikri okurken tesbihini kendi sayısıyla sınırlı görmez; yaratılmışların çokluğu, Allah’ın rızası, arşın azameti ve ilahî kelimelerin enginliği kadar hamd ile Rabbini yüceltmeyi niyaz eder.',
    category: 'Tesbih',
    defaultTarget: 3,
  ),
  DhikrItem(
    id: 'subhanallahil-azim',
    name: "Sübhanallahi ve bihamdihî, sübhanallahi'l-azîm",
    arabicText: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ سُبْحَانَ اللهِ الْعَظِيمِ',
    meaning: 'Allah’ı hamd ile tesbih eder, azamet sahibi Allah’ı yüceltirim.',
    longMeaning:
        'Hadiste birlikte zikredilen iki hafif ama mizanda ağır sözdür. Kul önce Rabbini hamd ile tesbih eder, sonra O’nun azametini kalbine yerleştirir. Rahmân’a sevimli olduğu bildirilen bu zikir, dili yumuşatır ve gönlü tevhidin vakarına çağırır.',
    category: 'Tesbih',
    defaultTarget: 100,
  ),
  DhikrItem(
    id: 'allahumme-salli',
    name: 'Allahümme salli alâ Muhammed',
    arabicText: 'اللهم صل على محمد',
    meaning: 'Allah’ım, Efendimiz Muhammed’e salat eyle.',
    longMeaning:
        'Müminin Peygamber Efendimiz’e muhabbetle yönelen duasıdır. Allah’ın ve meleklerinin ona salat ettiğini hatırlayan kul, bu sözle rahmet, bağlılık ve ümmet bilincini tazeler. Bir salavat, kalpte edep ve sevgi kapısını açan bereketli bir zikirdir.',
    category: 'Tesbih',
    defaultTarget: 100,
  ),
  DhikrItem(
    id: 'hasbunallah',
    name: 'Hasbünallahu ve ni‘me’l-vekîl',
    arabicText: 'حسبنا الله ونعم الوكيل',
    meaning: 'Allah bize yeter, O ne güzel vekildir.',
    longMeaning:
        'Korku büyüdüğünde imanı büyüten tevekkül sözüdür. Mümin bu zikirle tedbiri bırakmaz; fakat kalbinin dayanağını insanlarda değil Allah’ta bulur. Âl-i İmrân’da müminlerin zor zamanda söyledikleri bu cümle, sığınmanın vakarını ve güvenin huzurunu taşır.',
    category: 'Korunma',
    defaultTarget: 100,
  ),
  DhikrItem(
    id: 'hasbiyallah',
    name:
        'Hasbiyallahu lâ ilâhe illâ hû, aleyhi tevekkeltü ve hüve rabbü’l-arşi’l-azîm',
    arabicText:
        'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
    meaning:
        'Allah bana yeter. O’ndan başka ilah yoktur. Ben O’na güvenip dayandım; O büyük arşın Rabbidir.',
    longMeaning:
        'Kalbin yalnız Allah’a yaslandığını ilan eden güçlü bir tevekkül duasıdır. Kul, Rabbini yeter görür; O’ndan başka ilah olmadığını bilerek güvenini büyük arşın sahibine bırakır. Bu zikir, yalnızlık ve endişe anlarında imanı diri tutan bir sığınaktır.',
    category: 'Korunma',
    defaultTarget: 7,
  ),
  DhikrItem(
    id: 'ya-hayyu-ya-kayyum',
    name: 'Yâ Hayyü yâ Kayyûm, bi rahmetike estağîs',
    arabicText: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
    meaning: 'Ey Hayy ve Kayyûm olan Allah’ım! Rahmetinle yardım dilerim.',
    longMeaning:
        'Sıkıntı anında diri ve her şeyi ayakta tutan Rabb’e yönelen yalvarıştır. Kul bu duada kendi gücünü değil Allah’ın rahmetini arar; hâlini toparlayacak yardımın O’ndan geleceğini bilir. Bu söz, kalbi panikten çıkarıp rahmet kapısında beklemeyi öğretir.',
    category: 'Korunma',
    defaultTarget: 41,
  ),
  DhikrItem(
    id: 'rabbi-zidni-ilma',
    name: 'Rabbi zidnî ilmâ',
    arabicText: 'رب زدني علما',
    meaning: 'Rabbim, ilmimi artır.',
    longMeaning:
        'İlmi sadece bilgi çoğalması değil, kalbin aydınlanması olarak isteyen Kur’anî duadır. Kul bu sözle öğrenmenin de Allah’ın lütfu olduğunu kabul eder. Faydalı ilim, insanı kibre değil hayra, hikmete ve Rabbine daha bilinçli kulluğa götürsün diye niyaz eder.',
    category: 'Korunma',
    defaultTarget: 21,
  ),
  DhikrItem(
    id: 'rabbena-atina',
    name:
        'Rabbenâ âtinâ fi’d-dünyâ haseneten ve fi’l-âhireti haseneten ve kınâ azâbe’n-nâr',
    arabicText:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    meaning:
        'Rabbimiz! Bize dünyada da iyilik ver, ahirette de iyilik ver ve bizi cehennem azabından koru.',
    longMeaning:
        'Dünya ile ahireti aynı rahmet ufkunda isteyen kapsamlı bir Kur’an duasıdır. Kul bu sözle geçici hayatın iyiliğini de ebedî kurtuluşu da Rabbinden diler; ateşten korunmayı unutmaz. Dengeli, derin ve kuşatıcı bir sığınma niyazıdır.',
    category: 'Korunma',
    defaultTarget: 1,
  ),
  DhikrItem(
    id: 'yunus-duasi',
    name: 'Lâ ilâhe illâ ente sübhâneke innî küntü mine’z-zâlimîn',
    arabicText: 'لا إله إلا أنت سبحانك إني كنت من الظالمين',
    meaning:
        'Senden başka ilah yoktur. Seni eksikliklerden tenzih ederim. Ben zalimlerden oldum.',
    longMeaning:
        'Hz. Yûnus’un karanlıklar içinde Rabbine sığınırken söylediği Kur’anî duadır. Tevhid, tesbih ve kusur itirafı aynı nefeste buluşur. Kul bu zikri okurken çaresizliğini değil, Allah’ın merhametine açılan kapıyı hatırlar.',
    category: 'İstiğfar',
    defaultTarget: 1,
  ),
  DhikrItem(
    id: 'allahumme-ilmen-rizqan-amalan',
    name:
        'Allahümme innî es’elüke ilmen nâfian ve rizkan tayyiben ve amelen mütekabbelen',
    arabicText:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا',
    meaning:
        'Allah’ım! Senden faydalı ilim, temiz rızık ve kabul olunan amel isterim.',
    longMeaning:
        'Sabah duası olarak rivayet edilen bu niyaz, rızık ve bereketi faydalı ilim ve kabul olunan amelle birlikte ister. Kul, kazancının temiz, bilgisinin hayra açık, amelinin de Allah katında makbul olmasını diler.',
    category: 'Korunma',
    defaultTarget: 1,
  ),
  DhikrItem(
    id: 'allahumme-rabben-nas-ishfi',
    name: 'Allahümme rabbe’n-nâs, ezhibi’l-be’s, işfi ente’ş-Şâfî',
    arabicText:
        'اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَأْسَ، اشْفِ أَنْتَ الشَّافِي',
    meaning:
        'Allah’ım, insanların Rabbi! Sıkıntıyı gider, şifa ver; şifa veren Sensin.',
    longMeaning:
        'Hastalık ve kırgınlık hâlinde Allah’ın Şâfî oluşuna sığınan nebevî bir duadır. Kul bu sözle şifayı sebeplerden değil, sebepleri de yaratan Rabbinden bilir.',
    category: 'Korunma',
    defaultTarget: 1,
  ),
  DhikrItem(
    id: 'eselullahal-azim-yashfik',
    name: 'Es’elullâhe’l-azîm rabbe’l-arşi’l-azîm en yeşfiyek',
    arabicText:
        'أَسْأَلُ اللَّهَ الْعَظِيمَ رَبَّ الْعَرْشِ الْعَظِيمِ أَنْ يَشْفِيَكَ',
    meaning:
        'Yüce arşın Rabbi olan büyük Allah’tan sana şifa vermesini isterim.',
    longMeaning:
        'Hasta olan kimse için okunan kısa ve güçlü bir şifa duasıdır. Allah’ın azameti ve arşın Rabbi oluşu anılarak rahmet ve afiyet kapısı çalınır.',
    category: 'Korunma',
    defaultTarget: 7,
  ),
  DhikrItem(
    id: 'rabbena-hablana-min-azwajina',
    name: 'Rabbenâ heb lenâ min ezvâcinâ ve zürriyyâtinâ kurrate a‘yun',
    arabicText:
        'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
    meaning:
        'Rabbimiz! Eşlerimizden ve neslimizden göz aydınlığı ihsan et; bizi takvâ sahiplerine önder kıl.',
    longMeaning:
        'Aile, sevgi ve nesil için Kur’an’da öğretilen zarif bir duadır. Kul bu niyazla yakın ilişkilerinin huzur, merhamet ve takvâ ekseninde güçlenmesini ister.',
    category: 'Korunma',
    defaultTarget: 1,
  ),
  DhikrItem(
    id: 'ihdinas-siratal-mustakim',
    name: 'İhdina’s-sırâta’l-müstakîm',
    arabicText: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
    meaning: 'Bizi dosdoğru yola ilet.',
    longMeaning:
        'Fâtiha sûresinin merkezindeki hidayet duasıdır. Kul, bilgisinin, kararlarının ve hayat yönünün dosdoğru yola bağlanmasını Allah’tan ister.',
    category: 'Korunma',
    defaultTarget: 1,
  ),
  DhikrItem(
    id: 'rabbi-shrah-li-sadri',
    name: 'Rabbişrah lî sadrî ve yessir lî emrî',
    arabicText:
        'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِنْ لِسَانِي يَفْقَهُوا قَوْلِي',
    meaning:
        'Rabbim! Gönlüme ferahlık ver, işimi kolaylaştır; dilimdeki bağı çöz ki sözümü anlasınlar.',
    longMeaning:
        'Hz. Mûsâ’nın vazife ve tebliğ öncesi yaptığı Kur’anî duadır. İlim, anlatma, doğru karar ve zor işi kolaylaştırma niyetlerinde kalbe genişlik ister.',
    category: 'Korunma',
    defaultTarget: 1,
  ),
  DhikrItem(
    id: 'bismillah-alladhi-la-yadurru',
    name:
        'Bismillâhillezî lâ yadurru me‘asmihî şey’ün fi’l-ardı ve lâ fi’s-semâ',
    arabicText:
        'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
    meaning:
        'Allah’ın adıyla; O’nun adı anıldığında yerde ve gökte hiçbir şey zarar veremez. O işitendir, bilendir.',
    longMeaning:
        'Sabah ve akşam korunma niyetiyle okunan nebevî zikirlerdendir. Kul, bütün zarar ihtimallerinin üstünde Allah’ın adının sığınağına girer.',
    category: 'Korunma',
    defaultTarget: 3,
  ),
  DhikrItem(
    id: 'audhu-bikalimatillah',
    name: 'Eûzü bi-kelimâtillâhi’t-tâmmâti min şerri mâ halak',
    arabicText:
        'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    meaning:
        'Yarattıklarının şerrinden Allah’ın eksiksiz kelimelerine sığınırım.',
    longMeaning:
        'Konaklama, gece ve korunma niyetlerinde rivayet edilen sığınma duasıdır. Kısa lafzıyla kulun aczini ve Allah’ın koruyucu kudretini bir araya getirir.',
    category: 'Korunma',
    defaultTarget: 3,
  ),
  DhikrItem(
    id: 'muawwidhat-after-prayer',
    name: 'İhlâs, Felak ve Nâs sûreleri',
    arabicText:
        'قُلْ هُوَ اللَّهُ أَحَدٌ، قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ، قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
    meaning:
        'Allah’ın birliğini ikrar edip bütün görünür ve görünmez şerlerden O’na sığınma sûreleri.',
    longMeaning:
        'Namazlardan sonra okunması tavsiye edilen bu sûreler tevhid ve korunma niyetini birleştirir. Sabah ve akşam tekrarlarıyla kalbi Allah’ın birliğine ve himayesine yöneltir.',
    category: 'Korunma',
    defaultTarget: 3,
  ),
];
