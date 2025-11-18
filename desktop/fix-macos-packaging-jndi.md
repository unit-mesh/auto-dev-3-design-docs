# Fix: macOS Packaging JNDI Missing Module

## Problem

When running the packaged macOS application, it failed with:
```
Exception in thread "main" java.lang.NoClassDefFoundError: javax/naming/NamingException
Caused by: java.lang.ClassNotFoundException: javax.naming.NamingException
```

This error occurred because:
- Logback (used for logging) requires JNDI (Java Naming and Directory Interface) APIs
- In JDK 17+, the `java.naming` module is not included by default in custom runtimes
- Compose Desktop's jlink packaging creates a minimal JDK runtime without this module

## Solution

Added the `java.naming` module to the Compose Desktop packaging configuration in `mpp-ui/build.gradle.kts`:

```kotlin
compose.desktop {
    application {
        mainClass = "cc.unitmesh.devins.ui.MainKt"

        // Add JVM modules needed at runtime
        jvmArgs += listOf(
            "--add-modules", "java.naming"
        )

        nativeDistributions {
            // ...

            // Include java.naming module in the packaged runtime
            modules("java.naming")

            // ...
        }
    }
}
```

## Testing

1. Build the package:
   ```bash
   ./gradlew :mpp-ui:packageDistributionForCurrentOS --no-daemon
   ```

2. Run the packaged app:
   ```bash
   ./mpp-ui/build/compose/binaries/main/app/AutoDev\ Desktop.app/Contents/MacOS/AutoDev\ Desktop
   ```

3. Verify no `javax.naming.NamingException` errors appear

## Related

- Compose Desktop jlink: https://github.com/JetBrains/compose-multiplatform/tree/master/tutorials/Native_distributions_and_local_execution
- JDK Modules: https://docs.oracle.com/en/java/javase/17/docs/api/java.naming/module-summary.html
