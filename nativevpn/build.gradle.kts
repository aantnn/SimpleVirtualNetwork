import org.jetbrains.kotlin.cli.jvm.main

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}


fun loadProperties(filename: String): Map<String, String> {
    val properties = mutableMapOf<String, String>()
    file(filename).readLines().forEach { line ->
        if (line.isNotBlank() && !line.startsWith("#")) {
            val parts = line.split("=", limit = 2)
            if (parts.size == 2) {
                properties[parts[0].trim()] = parts[1].trim()
            }
        }
    }
    return properties
}

val versions = loadProperties("deps.txt")

android {
    sourceSets {

    }
    namespace = "ru.valishin.nativevpn"
    compileSdk = 36

    defaultConfig {
        minSdk = 24

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
        externalNativeBuild {
            cmake {
                cppFlags("")
                arguments(
                    *versions.map { (key, value) ->
                        "-D$key=$value"
                    }.toTypedArray()
                )
                //arguments("-G", "Unix Makefiles", "-DCMAKE_MAKE_PROGRAM=/var/home/a/Android/cmake/3.22.1/bin/make")
                //arguments("-DCMAKE_C_FLAGS=-I${project.projectDir.absolutePath}/src/main/cpp/include" )
            }
        }
        targetSdk = 36
    }


    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    externalNativeBuild {
        cmake {
            path("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    ndkVersion = "28.0.13004108"
    buildToolsVersion = "36.0.0"
}

dependencies {

    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
}