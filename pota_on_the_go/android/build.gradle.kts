allprojects {
    repositories {
        google()
        mavenCentral()
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

subprojects {
    if (name == "isar_flutter_libs") {
        plugins.withId("com.android.library") {
            val androidExtension = extensions.findByName("android") ?: return@withId
            val compileSdkVersionMethods = androidExtension.javaClass.methods.filter {
                it.name == "compileSdkVersion" && it.parameterCount == 1
            }
            val getNamespaceMethod = androidExtension.javaClass.methods.firstOrNull {
                it.name == "getNamespace" && it.parameterCount == 0
            }
            val setNamespaceMethod = androidExtension.javaClass.methods.firstOrNull {
                it.name == "setNamespace" && it.parameterCount == 1
            }

            val currentNamespace = getNamespaceMethod?.invoke(androidExtension) as? String
            if (currentNamespace.isNullOrBlank()) {
                setNamespaceMethod?.invoke(androidExtension, "dev.isar.isar_flutter_libs")
            }

            val intCompileSdkMethod = compileSdkVersionMethods.firstOrNull {
                val parameterType = it.parameterTypes.firstOrNull()
                parameterType == Int::class.javaPrimitiveType ||
                    parameterType == Int::class.javaObjectType
            }
            val stringCompileSdkMethod = compileSdkVersionMethods.firstOrNull {
                it.parameterTypes.firstOrNull() == String::class.java
            }

            when {
                intCompileSdkMethod != null -> intCompileSdkMethod.invoke(androidExtension, 36)
                stringCompileSdkMethod != null ->
                    stringCompileSdkMethod.invoke(androidExtension, "android-36")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
