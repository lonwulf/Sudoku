# App-specific R8 rules for release builds.
# Flutter and the plugins in use (Sentry, jni) ship their own consumer rules,
# so nothing is needed here yet. Add -keep rules for classes accessed via
# reflection or JNI from app code.
