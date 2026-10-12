part of 'main.dart';

Map<String, dynamic> _encodeRecords(AppModel model) => {
  'schemaVersion': 1,
  'includeEmptyItems': model.includeEmptyItems,
  'imageCursor': model._imageCursor,
  'properties': [
    for (final property in model.properties)
      {
        'id': property.id,
        'name': property.name,
        'address': property.address,
        'image': property.image,
      },
  ],
  'inspections': [
    for (final inspection in model.inspections)
      {
        'id': inspection.id,
        'propertyId': inspection.propertyId,
        'type': inspection.type.name,
        'date': inspection.date.toIso8601String(),
        'status': inspection.status.name,
        'updatedAt': inspection.updatedAt.toIso8601String(),
        'landlordSignature': _encodeSignature(inspection.landlordSignature),
        'tenantSignature': _encodeSignature(inspection.tenantSignature),
        'rooms': [
          for (final room in inspection.rooms)
            {
              'name': room.name,
              'condition': room.condition.name,
              'note': room.note,
              'photoAssets': room.photoAssets,
              'issues': [
                for (final issue in room.issues)
                  {
                    'id': issue.id,
                    'item': issue.item,
                    'condition': issue.condition.name,
                    'severity': issue.severity.name,
                    'note': issue.note,
                  },
              ],
            },
        ],
      },
  ],
};

Map<String, dynamic>? _encodeSignature(SignatureRecord? value) => value == null
    ? null
    : {'name': value.name, 'signedAt': value.signedAt.toIso8601String()};

SignatureRecord? _decodeSignature(dynamic value) => value == null
    ? null
    : SignatureRecord(
        name: value['name'] as String,
        signedAt: DateTime.parse(value['signedAt'] as String),
      );

AppModel _decodeRecords(Map<String, dynamic> data) {
  if (data['schemaVersion'] != 1) {
    throw const FormatException(
      'This record file uses an unsupported version.',
    );
  }
  final model = AppModel._(
    includeEmptyItems: data['includeEmptyItems'] as bool,
    properties: [
      for (final property in data['properties'] as List)
        PropertyRecord(
          id: property['id'] as String,
          name: property['name'] as String,
          address: property['address'] as String,
          image: property['image'] as String,
        ),
    ],
    inspections: [
      for (final inspection in data['inspections'] as List)
        InspectionRecord(
          id: inspection['id'] as String,
          propertyId: inspection['propertyId'] as String,
          type: InspectionType.values.byName(inspection['type'] as String),
          date: DateTime.parse(inspection['date'] as String),
          status: InspectionStatus.values.byName(
            inspection['status'] as String,
          ),
          updatedAt: DateTime.parse(inspection['updatedAt'] as String),
          landlordSignature: _decodeSignature(inspection['landlordSignature']),
          tenantSignature: _decodeSignature(inspection['tenantSignature']),
          rooms: [
            for (final room in inspection['rooms'] as List)
              RoomRecord(
                name: room['name'] as String,
                condition: RoomCondition.values.byName(
                  room['condition'] as String,
                ),
                note: room['note'] as String,
                photoAssets: List<String>.from(room['photoAssets'] as List),
                issues: [
                  for (final issue in room['issues'] as List)
                    IssueRecord(
                      id: issue['id'] as String,
                      item: issue['item'] as String,
                      condition: RoomCondition.values.byName(
                        issue['condition'] as String,
                      ),
                      severity: IssueSeverity.values.byName(
                        issue['severity'] as String,
                      ),
                      note: issue['note'] as String,
                    ),
                ],
              ),
          ],
        ),
    ],
  );
  model._imageCursor = data['imageCursor'] as int;
  return model;
}
