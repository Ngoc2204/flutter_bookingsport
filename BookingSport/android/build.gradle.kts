val flutterRenderer = "skia"
val gradlePropertiesFile = rootProject.file("gradle.properties")

if (!gradlePropertiesFile.readText().contains("flutter.renderer")) {
    gradlePropertiesFile.appendText("\nflutter.renderer=$flutterRenderer\n")
}

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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
