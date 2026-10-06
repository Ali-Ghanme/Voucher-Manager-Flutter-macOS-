allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        if (extensions.findByName("android") != null) {
            val android = extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            if (android.namespace.isNullOrEmpty()) {
                android.namespace = "dev.isar.${name}"
            }
            
            // استدعاء الدوال (Method Calls) لتفادي قيود النوع الذكي لكوتلن
            android.compileSdkVersion(34)
            android.defaultConfig.targetSdkVersion(34) 
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

plugins {
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}