import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/empty_active_profile_home_body.dart';
import 'package:hiddify/features/home/widget/empty_profiles_home_body.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_footer.dart';
import 'package:hiddify/providers/device_info_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAndroidTvAsync = ref.watch(isAndroidTvProvider);

    return isAndroidTvAsync.when(
      data: (isTv) {
        if (isTv) {
          return const _HomePageTv();
        } else {
          return const _HomePageMobile();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text("Ошибка: ${error.toString()}"),
        ),
      ),
    );
  }
}

class _HomePageTv extends HookConsumerWidget {
  const _HomePageTv({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      body: FocusScope(
        autofocus: true,
        child: CustomScrollView(
          slivers: [
            NestedAppBar(
              title: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: t.general.appTitle),
                    const TextSpan(text: " "),
                    const WidgetSpan(
                      child: AppVersionLabel(),
                      alignment: PlaceholderAlignment.middle,
                    ),
                  ],
                ),
              ),
              actions: [
                // Кнопки, специфичные для Android TV, можно добавить здесь, если необходимо
              ],
            ),
            // Основное содержимое для Android TV
            activeProfile.when(
              data: (profile) {
                if (profile != null) {
                  return MultiSliver(
                    children: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  ConnectionButton(),
                                  // Gap(16),
                                  // ActiveProxyDelayIndicator(),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  const AddProfileViaTelegramButton(),
                                  const Gap(16),
                                  // Кнопка меню для Android TV
                                  ElevatedButton(
                                    onPressed: () => _showTvMenu(context, ref),
                                    child: Text(ref.read(translationsProvider).general.menu),
                                  ),
                                ],
                              ),
                            ),
                            ProfileTile(
                              profile: profile,
                              isMain: true,
                            ),
                            // if (MediaQuery.sizeOf(context).width < 840)
                            const ActiveProxyFooter(),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return hasAnyProfile.when(
                    data: (hasProfile) {
                      if (hasProfile) {
                        return const EmptyActiveProfileHomeBody();
                      } else {
                        return const EmptyProfilesHomeBody();
                      }
                    },
                    loading: () => const SliverToBoxAdapter(),
                    error: (error, _) => SliverToBoxAdapter(
                      child: Text("Ошибка: ${error.toString()}"),
                    ),
                  );
                }
              },
              loading: () => const SliverToBoxAdapter(),
              error: (error, _) => SliverToBoxAdapter(
                child: Text("Ошибка: ${error.toString()}"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTvMenu(BuildContext context, WidgetRef ref) {
    final t = ref.read(translationsProvider);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(t.home.addProfileViaTelegram),
              onTap: () {
                Navigator.pop(context);
                const AddConfigRoute().push(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: Text(t.home.viewAllProfiles),
              onTap: () {
                Navigator.pop(context);
                const ProfilesOverviewRoute().push(context);
              },
            ),
            // Выбор приложений для проксирования
            ListTile(
              leading: const Icon(Icons.apps),
              title: Text(t.home.perAppProxy),
              onTap: () {
                Navigator.pop(context);
                const PerAppProxyRoute().push(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_applications),
              title: Text(t.configOptions.overview),
              onTap: () {
                Navigator.pop(context);
                const ConfigOptionsRoute().push(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(t.home.settings),
              onTap: () {
                Navigator.pop(context);
                const SettingsRoute().push(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(t.about.pageTitle),
              onTap: () {
                Navigator.pop(context);
                const AboutRoute().push(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class _HomePageMobile extends HookConsumerWidget {
  const _HomePageMobile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          NestedAppBar(
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: t.general.appTitle),
                  const TextSpan(text: " "),
                  const WidgetSpan(
                    child: AppVersionLabel(),
                    alignment: PlaceholderAlignment.middle,
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => const QuickSettingsRoute().push(context),
                icon: const Icon(FluentIcons.options_24_filled),
                tooltip: t.config.quickSettings,
              ),
              IconButton(
                onPressed: () => const AddProfileRoute().push(context),
                icon: const Icon(FluentIcons.add_circle_24_filled),
                tooltip: t.profile.add.buttonText,
              ),
            ],
          ),
          // Основное содержимое для обычного Android
          activeProfile.when(
            data: (profile) {
              if (profile != null) {
                return MultiSliver(
                  children: [
                    ProfileTile(profile: profile, isMain: true),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                ConnectionButton(),
                                ActiveProxyDelayIndicator(),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                const AddProfileViaTelegramButton(),
                                const Gap(16),
                                OutlinedButton.icon(
                                  onPressed: () => const AddProfileRoute().push(context),
                                  icon: const Icon(FluentIcons.add_24_regular),
                                  label: Text(t.profile.add.buttonText),
                                ),
                              ],
                            ),
                          ),
                          if (MediaQuery.sizeOf(context).width < 840) const ActiveProxyFooter(),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return hasAnyProfile.when(
                  data: (hasProfile) {
                    if (hasProfile) {
                      return const EmptyActiveProfileHomeBody();
                    } else {
                      return const EmptyProfilesHomeBody();
                    }
                  },
                  loading: () => const SliverToBoxAdapter(),
                  error: (error, _) => SliverToBoxAdapter(
                    child: Text("Ошибка: ${error.toString()}"),
                  ),
                );
              }
            },
            loading: () => const SliverToBoxAdapter(),
            error: (error, _) => SliverToBoxAdapter(
              child: Text("Ошибка: ${error.toString()}"),
            ),
          ),
        ],
      ),
    );
  }
}

class AddProfileViaTelegramButton extends HookConsumerWidget {
  const AddProfileViaTelegramButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return ElevatedButton.icon(
      onPressed: () => const AddConfigRoute().push(context),
      icon: const Icon(FluentIcons.add_24_regular),
      label: Text(t.home.addProfileViaTelegram),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.about.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 1,
        ),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
