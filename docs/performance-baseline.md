# قياس يلا ماركت على Android

تشغيل قياس الأداء منفصل عن تحسينه. هذه الأدوات لا تغير البطاقات أو الشبكات أو
الأعمال. كل بيلد يحمل `PERFORMANCE_TEST_BUILD=true` له معرّف مستقل
`com.yallamarket.app.performance`؛ لا يستبدل التطبيق الأصلي. في هذا البيلد فقط
تُعطل Firebase/Facebook التلقائية وخدمات Firebase الخلفية ورفع خرائط Crashlytics،
ويُسمح بالـHTTP المحلي. لا توزع APK القياس. البيلد المعتاد يحتفظ بإعداداته.

## البيانات والأجهزة

استخدم الموبايل الحقيقي، وسجل الطراز/Android/RAM/ABI والتردد الفعلي والبطارية
والحرارة والسطوع وإعدادات الوصول والأنيميشن قبل الجلسة. الأداة لا تغير هذه
الإعدادات. إذا اختلف التردد، مرره إلى `PERF_REFRESH_HZ` بدل افتراض60Hz.
تجنّب اللمس اليدوي أثناء الجولات. وجود شحن USB يجعل البطارية ملاحظة وصفية،
ولا يتيح استنتاج استهلاك طاقة دقيقًا. لا تعمم جهازًا واحدًا على أجهزة4GB أو iOS.

من جذر `yalla_market`:

```powershell
python tool/performance_android.py --adb PATH_TO_ADB --device DEVICE_ID --output build/performance/device
$env:PERF_OUTPUT='build/performance/run-ar.raw.json'
flutter drive --no-dds --profile -d DEVICE_ID --driver=test_driver/performance_driver.dart --target=integration_test/performance_baseline_test.dart --dart-define=PERFORMANCE_TEST_BUILD=true --dart-define=PERF_SCOPE=all --dart-define=PERF_LANGUAGE=ar --dart-define=PERF_REFRESH_HZ=60 --dart-define=PERF_RUN_ID=baseline-001
```

القيم المتاحة لـ`PERF_SCOPE`: all،store،category،browse_search،lists،search،navigation،soak.
يمكن اختيار كتالوج واحد باستخدام `PERF_PRODUCT_COUNT=1000`. القياس يستخدم
مستودعات صناعية وشاشات الإنتاج نفسها. الاختبارات الحالية تبني العناصر عند
الحاجة وتحمّل المنتجات بدفعات30؛ لا تستخدم خوارزمية المتجر المؤرشفة ذات100
منتج. الصور الافتراضية محلية متكررة؛ لا تثبت تكلفة آلاف صور الشبكة المختلفة.

لكل كتالوج100/1000/10000: ثلاث جولات تمرير >=30ث، وثلاث جولات تغيير فئة، كل
منها20 انتقالًا. أول جولة والأخريات محفوظة منفصلة. القوائم تشمل الرئيسية
والمفضلة والإشعارات والطلبات، والبحث30 تفاعلًا، والتنقل30 دورة. الانتهاء من
`pumpAndSettle` تعريف نهاية التفاعل في هذه الاختبارات؛ هو أوسع من زمن استجابة
Cubit وحده. الافتراضي لنقرات الفئات هو مسار أحداث الجهاز
`PERF_NATIVE_INPUT=true`، و`PERF_FORCE_TEST_SEMANTICS=false` يمنع فرض semantics
إضافية من الاختبار مع احترام طلب النظام لها. إيماءات التمرير ما زالت من
WidgetTester. تُسجل الإعدادات مع النتائج؛ لا تُخلط الجولات القديمة ذات مؤشر
الاختبار وsemantics المفروضة مع الإعدادات الجديدة دون توضيح أثر أداة القياس.

شغل البحث والتصفح مرة أخرى بالإنجليزية. استخدم `PERF_CAPTURE_TRACE=true`
في جولة تشخيص منفصلة لتصدير timeline؛ لا تخلطها بقبول الإطارات. ملفات
FrameTiming الخام محفوظة حتى لو لم ينجح معيار السلاسة، ويحفظ driver الرد عند
فشل الاختبار. معيار المقارنة: <5% تجاوز للميزانية لكل من UI وRaster، ولا إطار
>100ms. تُقرب ميزانية الميكروثانية إلى16667 عند60Hz؛ هذه ليست طريقة لحساب FPS.

التلخيص من جذر `yalla_backend`:

```powershell
.venv/Scripts/python.exe tools/performance/summarize.py ../yalla_market/build/performance/run-ar.raw.json ../yalla_market/build/performance/run-ar.summary.json
```

## اتصال Staging الحقيقي

جهز Docker حسب دليل السيرفر. شغل الاختبار التالي، وفي نافذة أخرى شغل
`prepare_mobile.py` بعد بدء التثبيت. الاعتمادات تُدفع إلى مجلد التطبيق المعزول،
ولا تمر في dart-defines أو سطر أوامر Gradle أو التقرير.

```powershell
$env:PERF_OUTPUT='build/performance/staging.raw.json'
flutter drive --no-dds --profile -d DEVICE_ID --driver=test_driver/performance_driver.dart --target=integration_test/performance_staging_test.dart --dart-define=PERFORMANCE_TEST_BUILD=true --dart-define=API_BASE_URL=http://127.0.0.1:18081
```

من جذر السيرفر:

```powershell
.venv/Scripts/python.exe tools/performance/prepare_mobile.py --adb PATH_TO_ADB --device DEVICE_ID
```

الاختبار يقيس ثلاث جولات متجر متصل بالـAPI والصور الحقيقية الصناعية، ثم30
تغيير كمية و30 معاينة و30 إنشاء طلب مستقل. أزمنة `checkout_*` تنتهي عند Cubit.
بعدها30 رحلة واجهة: السلة، زيادة الكمية، المعاينة، اختيار العنوان وتأكيد الطلب
حتى شاشة النجاح، بأزمنة كل خطوة ووقت الرحلة ومعرّفات نجاح مستقلة. أزمنة `ui_*`
تشمل انتظار استقرار الواجهة؛ شاشة اختيار العنوان تُفتح برمجيًا، وصوت النجاح
مستبعد من الاختبار. شبكة هذا التشغيل USB loopback، وليست WiFi مقاسة.
لا تُنسب له محاكاة فقد الحزم أو سرعات الإنترنت دون gateway مضبوط.

## فتح Release

ابنِ observer بدل integration_test، ثم ثبته فقط بعد انتهاء جولات Profile:

```powershell
$env:SKIP_CRASHLYTICS_MAPPING_UPLOAD='true'
flutter build apk --release --target=tool/performance_startup.dart --dart-define=PERFORMANCE_TEST_BUILD=true --dart-define=API_BASE_URL=http://127.0.0.1:18081 --dart-define=MAPTILER_API_KEY=performance-no-map --dart-define=ENABLE_ONBOARDING=false
```

تظل إعدادات توقيع Release المعتادة مطلوبة. لا تُقاس الخرائط بهذا المفتاح
الصناعي. وصل المنفذ بـ`adb reverse tcp:18081 tcp:18081`، ثم:

```powershell
python tool/performance_android.py --adb PATH_TO_ADB --device DEVICE_ID --output build/performance/startup --startup
```

الأداة تسجل30 تشغيلًا بعد إغلاق العملية مع الاحتفاظ بكاش القرص، و30 عودة من
الخلفية. `--first-install` يستخدم فقط بعد تثبيت جديد للحزمة التجريبية، وليس
تحديثًا فوق بياناتها. تحفظ النتائج الجزئية لكل محاولة فورًا. Android TotalTime
يبقى باسمه، وعلامة أول Raster تبدأ من Dart main، وعلامة المحتوى تبدأ من نفس
النقطة وتنتهي عند اكتمال انتقال شاشة الدخول/الترحيب ورسم إطارها. في العودة يبدأ القياس من
Dart lifecycle callback. هذه حدود ساعات مختلفة؛ لا تجمعها أو تسمها جميعًا
زمنًا منذ الضغط على الأيقونة. الصور قد تظل تُحمّل. Firebase مستبعد في بيئة
القياس، لذلك لا تمثل الأرقام startup الإنتاج بجميع خدماته.

## الذاكرة والاستخدام الممتد

```powershell
$env:PERF_OUTPUT='build/performance/memory-session.raw.json'
flutter drive --no-dds --profile -d DEVICE_ID --driver=test_driver/performance_driver.dart --target=integration_test/performance_memory_test.dart --dart-define=PERFORMANCE_TEST_BUILD=true --dart-define=PERF_SOAK_MINUTES=30
```

احفظ خرج الأمر في ملف ignored، ثم بالتوازي:

```powershell
dart run tool/performance_memory.dart build/performance-memory.log build/performance/memory
python tool/performance_android.py --adb PATH_TO_ADB --device DEVICE_ID --output build/performance/device-session --sample-seconds 1800
```

توجد نقاط توقف baseline بعد إحماء3 دورات، ثم بعد20 دورة، ثم بعد30 دقيقة.
جامع الذاكرة يحفظ allocation profile بعد GC وheap snapshot ثنائيًا في كل نقطة،
وفروقًا وretaining paths لعينة من أصناف الحالة/controllers التي زاد عددها.
هذا تشخيص منفصل ذو overhead، ولا يدخل في قبول الإطارات. نمو الكاش أو عدد
كائنات صنف لا يثبت تسريبًا. snapshots قد تحتوي بيانات runtime؛ تظل في `build/`
ولا تُضاف إلى Git أو يُطبع محتواها. `vm_service` اعتماد تطوير فقط، بنفس الإصدار
المحلول سابقًا من Flutter، لقراءة هذه الأدلة من المضيف.

جامع الموارد يستخدم PSS من `dumpsys meminfo` ونافذة CPU الثانية لمدة ثانية
من `top` كل خمس ثوانٍ؛ النسبة نسبة إلى نواة واحدة. يحتفظ بتوقيت العينة، ولا
يُفسر `dumpsys cpuinfo` القديم باعتباره قياسًا لحظيًا. تؤثر أدوات التشخيص على
الجلسة؛ أزمنة CPU عينة وليست ذروة مستمرة.

## التغطية الناقصة

الشبكة المضبوطة تحتاج gateway يدعم الاتجاهين وRTT وفقد الحزم: عادي20/5Mbps
و50ms؛ ضعيف1/0.256Mbps و300ms وفقد1%؛ ثم فصل واستعادة. إن لم يتوفر، سجلها
غير مقاسة، ولا تستخدم `sleep` في repository كبديل. اختبارات host/debug
وظيفية وليست دليل سلاسة جهاز. إتمام التقرير يعني نتيجة أو سبب تعذر لكل
سيناريو، مع توثيق resource parity والسياق والعينات والمحاولات الفاشلة.

## تشغيل موثوق وحماية قياس أول تثبيت

`--first-install` أصبح يتطلب `--fresh-install-apk` و`--aapt`: تتحقق الأداة من
معرّف APK المعزول، ومن إزالة الحزمة وغيابها ثم تثبيتها دون تشغيل سابق للمستخدم0.
أي فشل يوقف القياس ويحفظ `verified=false`، ولا يمس الحزمة الأصلية.
اختر مجلد نتائج جديدًا. لقياس عينة أول تثبيت فقط دون تكرار العينات السابقة:

```powershell
python tool/performance_android.py --adb PATH_TO_ADB --device DEVICE_ID --output build/performance/fresh-NEW_ID --startup --first-install --first-install-only --fresh-install-apk ISOLATED_RELEASE_APK --aapt PATH_TO_AAPT
```

لفصل تحذيرات stderr عن كود الخروج الأصلي، استخدم المشغل التالي، واضبط مسار
artifact جديدًا مطابقًا لـ`PERF_OUTPUT`. يحفظ stdout وstderr و`execution.json`؛
لا يعتبر كود0 مع نتيجة غير مكتملة نجاحًا، ولا يخفي كود فشل مع نتيجة مكتملة:

```powershell
$env:PERF_OUTPUT='build/performance/run-NEW_ID.raw.json'
python tool/performance_command.py --output build/performance/execution-NEW_ID --artifact build/performance/run-NEW_ID.raw.json -- PATH_TO_FLUTTER_BAT drive --profile --no-dds -d DEVICE_ID --driver=test_driver/performance_driver.dart --target=integration_test/performance_lists_offers_test.dart --dart-define=PERFORMANCE_TEST_BUILD=true --dart-define=PERF_RESIDENT_LISTS_ONLY=true
```

السجلات تشخيصية محلية ignored، وقد تتضمن VM URI مؤقتة وتدفقات تطبيقات أخرى.
مرر stdout.log وstderr.log إلى منظف سجلات الأداء بعد اكتمال الجلسة وقبل مشاركتها.

## بروتوكولات القياس المصححة

لإعادة جزء رحلة الشراء على الواجهة فقط، استخدم target
`integration_test/performance_staging_test.dart` مع
`--dart-define=PERFORMANCE_TEST_BUILD=true --dart-define=PERF_PURCHASE_UI_ONLY=true`
وإعداد API المحلي المعزول وملف الحساب الخاص المعتادين. تختار الجولة مدينة تتوافق مع
عنوان fixture، ولا تختار المنطقة العامة تلقائيًا. لا تضف `PERF_PURCHASE_UI_ONLY` عند
الحاجة إلى جولات المتجر والقياسات عبر Cubit أيضًا.

لجمع حجم البيانات بعد drive، أضف `--keep-app-running` لأن تنظيف drive الافتراضي
يزيل حزمة الاختبار. ثم نفّذ:

```powershell
python tool/performance_android.py --adb PATH_TO_ADB --device DEVICE_ID --output build/performance/storage-NEW_ID --storage
```

تظل نتيجة تعذر القراءة `unavailable` وليست صفرًا. قياس بيانات حزمة Profile لا يمثل
حجم نسخة المتجر أو قياس البطارية؛ أغلق حزمة الاختبار وأزل reverse المحلي بعد الجلسة.

`search_navigation` يجمع البحث والتنقل دون إعادة جولات القوائم. إدخال البحث
في Profile يستخدم `EditableTextState.updateEditingValue` مع التحقق من حالة
الـCubit والنص والنتائج؛ `WidgetTester.enterText` ذو fake client غير صالح
لهذه الجلسة. المستودع الصناعي لا يثبت صحة ترتيب نتائج API.

`scroll_probe.dart` يعكس الاتجاه عند الحواف ويتحقق من حركة فعلية طوال30ث،
ويسجل المسافة وعدد الحركات. جولات البروتوكول القديم محفوظة، وتظل صلاحيتها
للحركة المستمرة محدودة. اختبار `performance_lists_offers_test.dart` يتصفح
PageView للعروض أفقيًا بثلاث جولات، ويقيس عدد عناصر القوائم المقيمة في الشجرة؛
هذا العدد لا يمثل إجمالي استدعاءات build عبر عمر الشاشة.

مراقب Release بالإصدار `interactive_entry_raster_v2` ينتظر انتهاء انتقال
شاشة الدخول ثم Raster الإطار الموافق للمحتوى. observer القديم يقيس البناء
فقط ويحتفظ به كتشخيص سابق. بعد إتمام startup يمكن دفع fixture الخاصة ثم:

```powershell
python tool/performance_android.py --adb PATH_TO_ADB --device DEVICE_ID --output build/performance/release-review --release-review
```

مراجعة Release تستدعي callbacks لعناصر الواجهة الفعلية، وتتحقق من تأكيد
الشراء والعزل عن push. ليست قياس لمس أو قياس startup مسجل الدخول.

ملاحظة دقة القياس: إذا فشل إلغاء تثبيت حزمة الاختبار، لا يكفي نجاح install
لإثبات تفريغ البيانات السابقة. سجّل محاولة ما بعد التثبيت بحدودها، ولا تسمها
أول تشغيل نظيف إلا مع دليل تحقق. أحداث بدء التشغيل تظل خامًا دون إعادة تسمية
أو حذف؛ يوضح سياق التقرير مدى صلاحية تفسيرها.
