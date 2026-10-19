plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

// release 签名用的密钥文件（由 CI 第一次运行时生成并提交到仓库）。
// 放在 android/app/ 下，所以这里相对本文件解析。
val releaseKeyStore = file("flow-release.jks")
val hasReleaseKey = releaseKeyStore.exists()

android {
    namespace = "com.zjzbs.flow"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.zjzbs.flow"
        minSdk = 26
        targetSdk = 34
        versionCode = 12
        versionName = "1.0.3"
    }

    signingConfigs {
        create("release") {
            // 侧载自用，不走商店，所以密钥提交在仓库里也无所谓；
            // 好处是每版签名一致，手机上可以直接覆盖安装。
            if (hasReleaseKey) {
                storeFile = releaseKeyStore
                storePassword = "flowflow"
                keyAlias = "flow"
                keyPassword = "flowflow"
            }
        }
    }

    buildTypes {
        release {
            // 打开 R8 混淆 + 资源压缩。debug 包的 Compose 没做任何优化，
            // 在手机上会明显掉帧；release 包顺滑得多。
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            if (hasReleaseKey) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        debug {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.6")

    val composeBom = platform("androidx.compose:compose-bom:2024.09.03")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-core")

    debugImplementation("androidx.compose.ui:ui-tooling")
}
