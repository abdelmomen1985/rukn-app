import 'package:flutter_test/flutter_test.dart';
import 'package:rukn_thamin/data/legal.dart';

/// Clause counts in rukn-site `src/data/legal.ts` (privacy and terms). Update these
/// together with the data when clauses are appended.
const _expectedClauses = {'privacy': 13, 'terms': 16};

void main() {
  test('both legal documents exist under their slugs', () {
    expect(legalDocs.keys.toSet(), {'privacy', 'terms'});
    expect(legalDocs['privacy']!.slug, 'privacy');
    expect(legalDocs['terms']!.slug, 'terms');
  });

  test('clause counts match the website source', () {
    for (final entry in _expectedClauses.entries) {
      expect(legalDocs[entry.key]!.clauses, hasLength(entry.value), reason: entry.key);
    }
  });

  test('every document has bilingual title, summary and an ISO updated date', () {
    for (final doc in legalDocs.values) {
      expect(doc.title.en.trim(), isNotEmpty, reason: '${doc.slug} title en');
      expect(doc.title.ar.trim(), isNotEmpty, reason: '${doc.slug} title ar');
      expect(doc.summary.en.trim(), isNotEmpty, reason: '${doc.slug} summary en');
      expect(doc.summary.ar.trim(), isNotEmpty, reason: '${doc.slug} summary ar');
      expect(DateTime.tryParse(doc.updated), isNotNull, reason: '${doc.slug} updated');
    }
  });

  test('every clause has bilingual heading and at least one block with text', () {
    for (final doc in legalDocs.values) {
      for (final clause in doc.clauses) {
        final where = '${doc.slug}#${clause.id}';
        expect(clause.heading.en.trim(), isNotEmpty, reason: '$where heading en');
        expect(clause.heading.ar.trim(), isNotEmpty, reason: '$where heading ar');
        expect(clause.blocks, isNotEmpty, reason: '$where blocks');
        for (final block in clause.blocks) {
          switch (block) {
            case LegalParagraph(:final text):
              expect(text.en.trim(), isNotEmpty, reason: '$where paragraph en');
              expect(text.ar.trim(), isNotEmpty, reason: '$where paragraph ar');
            case LegalList(:final items):
              expect(items, isNotEmpty, reason: '$where list');
              for (final item in items) {
                expect(item.en.trim(), isNotEmpty, reason: '$where item en');
                expect(item.ar.trim(), isNotEmpty, reason: '$where item ar');
              }
          }
        }
      }
    }
  });

  test('clause ids are unique within each document', () {
    for (final doc in legalDocs.values) {
      final ids = doc.clauses.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: doc.slug);
      for (final id in ids) {
        expect(RegExp(r'^[a-z-]+$').hasMatch(id), isTrue, reason: '${doc.slug} id "$id" is an anchor slug');
      }
    }
  });

  test('company block carries the registration numbers from the website', () {
    expect(legalCompany.commercialRegister, '7041480281');
    expect(legalCompany.vatNumber, '312482882500003');
    expect(legalCompany.email, 'info@alruknalthamin.com');
  });
}
