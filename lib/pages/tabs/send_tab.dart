import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/selected_files_page.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/network_info_provider.dart';
import 'package:localsend_app/provider/selected_files_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/widget/big_button.dart';
import 'package:localsend_app/widget/dialogs/add_file_dialog.dart';
import 'package:localsend_app/widget/dialogs/no_files_dialog.dart';
import 'package:localsend_app/widget/list_tile/device_list_tile.dart';
import 'package:localsend_app/widget/rotating_widget.dart';
import 'package:routerino/routerino.dart';

class SendTab extends ConsumerStatefulWidget {
  const SendTab({Key? key}) : super(key: key);

  @override
  ConsumerState<SendTab> createState() => _SendTabState();
}

class _SendTabState extends ConsumerState<SendTab> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final devices = ref.read(nearbyDevicesProvider.select((state) => state.devices));
      if (devices.isEmpty) {
        _scan();
      }
    });
  }

  void _scan() {
    final port = ref.read(settingsProvider.select((settings) => settings.port));
    final networkInfo = ref.read(networkInfoProvider);
    final localIp = networkInfo?.localIp;
    if (localIp != null) {
      ref.read(nearbyDevicesProvider.notifier).startScan(port: port, localIp: localIp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFiles = ref.watch(selectedFilesProvider);
    final myDevice = ref.watch(deviceInfoProvider);
    final nearbyDevicesState = ref.watch(nearbyDevicesProvider);
    final addOptions = [
      AddOption.file,
      if (defaultTargetPlatform == TargetPlatform.iOS) ...[
        AddOption.image,
        AddOption.video,
      ],
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      children: [
        const SizedBox(height: 20),
        if (selectedFiles.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              t.sendTab.selection.title,
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...List.generate(3, (index) {
                  final option = index < addOptions.length ? addOptions[index] : null;
                  return [
                    Expanded(
                      child: option == null
                          ? Container()
                          : BigButton(
                              icon: option.icon,
                              label: option.label,
                              onTap: () => option.select(ref),
                            ),
                    ),
                    const SizedBox(width: 15),
                  ];
                }).expand((e) => e).toList()
                  ..removeLast(),
              ],
            ),
          ),
        ] else ...[
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15, top: 15),
                  child: Text(
                    t.sendTab.selection.title,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Text(t.sendTab.selection.files(files: selectedFiles.length)),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Text(t.sendTab.selection.size(size: selectedFiles.fold(0, (prev, curr) => prev + curr.size).asReadableFileSize)),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...selectedFiles.map((file) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Opacity(
                              opacity: 1,
                              child: Icon(file.fileType.icon, size: 32),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () {
                        context.push(() => const SelectedFilesPage());
                      },
                      icon: const Icon(Icons.edit),
                      label: Text(t.general.edit),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton.icon(
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        if (addOptions.length == 1) {
                          addOptions.first.select(ref); // open directly
                          return;
                        }
                        context.pushBottomSheet(() => AddFileDialog(
                              parentRef: ref,
                              options: addOptions,
                            ));
                      },
                      icon: const Icon(Icons.add),
                      label: Text(t.general.add),
                    ),
                    const SizedBox(width: 15),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Text(t.sendTab.nearbyDevices, style: Theme.of(context).textTheme.subtitle1),
            RotatingWidget(
              duration: const Duration(seconds: 2),
              spinning: nearbyDevicesState.running,
              reverse: true,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: const CircleBorder(),
                ),
                onPressed: _scan,
                child: const Icon(Icons.sync),
              ),
            ),
          ],
        ),
        Hero(
          tag: 'this-device',
          child: DeviceListTile(
            device: myDevice,
            thisDevice: true,
          ),
        ),
        const SizedBox(height: 10),
        ...nearbyDevicesState.devices.map((device) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Hero(
              tag: 'device-${device.ip}',
              child: DeviceListTile(
                device: device,
                onTap: () {
                  final files = ref.read(selectedFilesProvider);
                  if (files.isEmpty) {
                    context.pushBottomSheet(() => const NoFilesDialog());
                   return;
                  }

                  ref.read(sendProvider.notifier).startSession(
                        target: device,
                        files: files,
                      );
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        Text(t.sendTab.help, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 50),
      ],
    );
  }
}