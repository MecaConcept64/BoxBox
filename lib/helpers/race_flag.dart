import 'package:flutter/material.dart';

/// Provider country labels include event names such as Miami and Emilia-Romagna.
String? raceCountryCode(String country) => const {
      'spain': 'ES',
      'espagne': 'ES',
      'barcelona-catalunya': 'ES',
      'azerbaijan': 'AZ',
      'azerbaïdjan': 'AZ',
      'australia': 'AU',
      'china': 'CN',
      'japan': 'JP',
      'bahrain': 'BH',
      'saudi arabia': 'SA',
      'miami': 'US',
      'united states': 'US',
      'usa': 'US',
      'las vegas': 'US',
      'canada': 'CA',
      'monaco': 'MC',
      'austria': 'AT',
      'great britain': 'GB',
      'united kingdom': 'GB',
      'uk': 'GB',
      'belgium': 'BE',
      'hungary': 'HU',
      'netherlands': 'NL',
      'italy': 'IT',
      'emilia-romagna': 'IT',
      'singapore': 'SG',
      'mexico': 'MX',
      'brazil': 'BR',
      'são paulo': 'BR',
      'sao paulo': 'BR',
      'qatar': 'QA',
      'abu dhabi': 'AE',
      'uae': 'AE',
      'united arab emirates': 'AE',
      'france': 'FR',
      'germany': 'DE',
      'portugal': 'PT',
      'turkey': 'TR',
      'russia': 'RU',
      'malaysia': 'MY',
      'india': 'IN',
      'south korea': 'KR',
      'south africa': 'ZA',
      'argentina': 'AR',
      'switzerland': 'CH',
      'sweden': 'SE',
      'morocco': 'MA',
      'chile': 'CL',
      'indonesia': 'ID',
    }[country.trim().toLowerCase()];

class RaceFlag extends StatelessWidget {
  final String country;
  const RaceFlag(this.country, {super.key});

  @override
  Widget build(BuildContext context) {
    final code = raceCountryCode(country);
    return SizedBox(
        width: 36,
        child: ExcludeSemantics(
          child: code == null
              ? Icon(Icons.outlined_flag,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)
              : Text(
                  String.fromCharCodes(code.codeUnits.map((c) => c + 127397)),
                  style:
                      const TextStyle(fontSize: 28, fontFamily: '', height: 1)),
        ));
  }
}
