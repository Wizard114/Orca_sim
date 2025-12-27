import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// --- [INICIO] CARREGAR CHAVE DE ASSINATURA ---
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
// --- [FIM] ---

android {
    namespace = "com.example.orca_sim"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.orca_sim"
        minSdk = flutter.minSdkVersion // Definido fixo para garantir compatibilidade
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // --- [INICIO] CONFIGURAÇÃO DE ASSINATURA ---
    signingConfigs {
        create("release") {
            // Só tenta ler se o arquivo key.properties existir e tiver as chaves
            if (keystoreProperties.isNotEmpty()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    // --- [FIM] ---

    buildTypes {
        getByName("release") {
            // Aplica a configuração de assinatura "release" criada acima
            signingConfig = signingConfigs.getByName("release")
            
            // Otimizações para deixar o app menor e mais difícil de hackear
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

apply(plugin = "com.google.gms.google-services")
