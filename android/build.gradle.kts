allprojects {
    repositories {
        // Aliyun mirrors (China)
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }

        // DevNeeds & Myket mirrors (Iran)
        maven { url = uri("https://maven.devneeds.ir/repository/google/") }
        maven { url = uri("https://maven.devneeds.ir/repository/maven-central/") }
        maven { url = uri("https://maven.myket.ir/repository/google/") }
        maven { url = uri("https://maven.myket.ir/repository/maven-central/") }

        mavenCentral()
        google()
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
