import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rental_report/main.dart';

void main() {
  test(
    'records, issues, sign-offs and export state survive a fresh model',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'rental-records-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final first = await AppModel.loadLocal(directory: directory);
      final property = first.addProperty(
        name: 'Harbor unit',
        address: '12 Harbor St',
      );
      final id = first.createInspection(
        propertyId: property.id,
        type: InspectionType.moveOut,
      );
      final room = first.inspectionById(id)!.rooms.first.name;
      first.updateRoomCondition(
        inspectionId: id,
        roomName: room,
        condition: RoomCondition.damaged,
      );
      first.updateRoomNote(
        inspectionId: id,
        roomName: room,
        note: 'Paint chipped at the door.',
      );
      first.addRoomPhoto(
        inspectionId: id,
        roomName: room,
        path: '${directory.path}/photo.jpg',
      );
      first.addIssue(
        inspectionId: id,
        roomName: room,
        item: 'Door',
        condition: RoomCondition.damaged,
        severity: IssueSeverity.medium,
        note: 'Visible chips',
      );
      first.captureSignature(
        inspectionId: id,
        role: SignatureRole.landlord,
        name: 'Alex',
      );
      first.setIncludeEmptyItems(false);
      first.markExported(id);

      final restored = await AppModel.loadLocal(directory: directory);
      expect(restored.properties.single.address, '12 Harbor St');
      final report = restored.inspections.single;
      expect(report.type, InspectionType.moveOut);
      expect(report.status, InspectionStatus.exported);
      expect(report.rooms.first.note, 'Paint chipped at the door.');
      expect(
        report.rooms.first.photoAssets.single,
        '${directory.path}/photo.jpg',
      );
      expect(report.rooms.first.issues.single.severity, IssueSeverity.medium);
      expect(report.landlordSignature!.name, 'Alex');
      expect(restored.includeEmptyItems, isFalse);

      restored.clearSignatures(id);
      final third = await AppModel.loadLocal(directory: directory);
      expect(third.inspections.single.landlordSignature, isNull);
    },
  );
}
