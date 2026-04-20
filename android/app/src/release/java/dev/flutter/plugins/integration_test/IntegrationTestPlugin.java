package dev.flutter.plugins.integration_test;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * Release-only no-op shim for Flutter's integration_test plugin.
 *
 * The main app keeps integration_test as a dev dependency for instrumentation
 * scenarios, but release compilation can still see a stale
 * GeneratedPluginRegistrant entry that references this plugin class.
 *
 * Shipping a no-op implementation in the release source set keeps release
 * builds green without affecting debug/integration-test behavior.
 */
public final class IntegrationTestPlugin implements FlutterPlugin {
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {}

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {}
}
