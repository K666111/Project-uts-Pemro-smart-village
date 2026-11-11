import 'package:flutter/material.dart';

import '../services/language_service.dart';
import '../utils/app_colors.dart';

class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  void _showLanguageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ValueListenableBuilder<String>(
            valueListenable: LanguageService.languageCode,
            builder: (context, selectedCode, child) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Bahasa',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pilih bahasa yang ingin digunakan di aplikasi.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: LanguageService.languages.length,
                        itemBuilder: (context, index) {
                          final language = LanguageService.languages[index];

                          final isSelected = selectedCode == language.code;

                          return ListTile(
                            leading: Text(
                              language.flag,
                              style: const TextStyle(fontSize: 26),
                            ),
                            title: Text(
                              language.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                  )
                                : null,
                            onTap: () async {
                              await LanguageService.changeLanguage(
                                language.code,
                              );

                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.languageCode,
      builder: (context, selectedCode, child) {
        final language = LanguageService.currentLanguage;

        return ListTile(
          leading: const Icon(Icons.language, color: AppColors.primary),
          title: const Text(
            'Bahasa Aplikasi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${language.flag} ${language.name}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showLanguageOptions(context),
        );
      },
    );
  }
}
