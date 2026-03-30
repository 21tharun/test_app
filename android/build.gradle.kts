import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
            force("androidx.appcompat:appcompat:1.6.1")
            force("androidx.annotation:annotation:1.9.1")
            force("androidx.emoji2:emoji2:1.4.0")
            force("androidx.emoji2:emoji2-views-helper:1.4.0")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        val android = project.extensions.findByName("android") as? BaseExtension
        android?.compileSdkVersion(36)
    }
}

// Forces removed to allow url_launcher and other modern plugins to use updated versions.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


