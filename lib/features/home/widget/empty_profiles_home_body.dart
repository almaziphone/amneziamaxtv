import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/providers/device_info_providers.dart'; // Import the provider
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EmptyProfilesHomeBody extends HookConsumerWidget {
  const EmptyProfilesHomeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final isAndroidTvAsync = ref.watch(isAndroidTvProvider);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: isAndroidTvAsync.when(
        data: (isAndroidTv) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t.home.emptyProfilesMsg),
            const Gap(16),
            if (!isAndroidTv)
              OutlinedButton.icon(
                onPressed: () => const AddProfileRoute().push(context),
                icon: const Icon(FluentIcons.add_24_regular),
                label: Text(t.profile.add.buttonText),
              ),
            if (!isAndroidTv) const Gap(16),
            ElevatedButton.icon(
              onPressed: () => const AddConfigRoute().push(context),
              icon: const Icon(FluentIcons.add_24_regular),
              label: Text(t.home.addProfileViaTelegram),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t.home.emptyProfilesMsg),
            const Gap(16),
            // Default to showing both buttons if we can't determine the device type
            OutlinedButton.icon(
              onPressed: () => const AddProfileRoute().push(context),
              icon: const Icon(FluentIcons.add_24_regular),
              label: Text(t.profile.add.buttonText),
            ),
            const Gap(16),
            ElevatedButton.icon(
              onPressed: () => const AddConfigRoute().push(context),
              icon: const Icon(FluentIcons.add_24_regular),
              label: Text(t.home.addProfileViaTelegram),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyActiveProfileHomeBody extends HookConsumerWidget {
  const EmptyActiveProfileHomeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(t.home.noActiveProfileMsg),
          const Gap(16),
          OutlinedButton(
            onPressed: () => const ProfilesOverviewRoute().push(context),
            child: Text(t.profile.overviewPageTitle),
          ),
        ],
      ),
    );
  }
}