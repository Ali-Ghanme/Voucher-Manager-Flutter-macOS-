# الحفاظ على ملفات الخدمات داخل META-INF مأمونة وموقعة
-keeppackagenames META-INF.services.**
-keepattributes InnerClasses,EnclosingMethod,Signature,AnnotationDefault

# منع تحوير أسماء ملفات الخدمات لتفادي تعارض التوقيع
-dontwarn META-INF.services.**