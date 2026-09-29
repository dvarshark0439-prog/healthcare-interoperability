import 'dart:convert';

import 'package:codexxx/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('demo patient can sign in and reach the dashboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MedifixApp(controller: HealthAppController.seeded()),
    );

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Demo Credentials'), findsOneWidget);

    await tester.tap(find.text('Sign in to dashboard'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back,'), findsOneWidget);
    expect(find.text('PATIENT DASHBOARD'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
  });

  testWidgets('new patient registration provisions a secure account', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MedifixApp(controller: HealthAppController.seeded()),
    );

    await tester.tap(find.text('New patient'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(4));

    await tester.enterText(fields.at(0), 'Akash Madhu');
    await tester.enterText(fields.at(1), 'akash@example.com');
    await tester.enterText(fields.at(2), 'Health123');
    await tester.enterText(fields.at(3), 'Sree Buddha Medical Network');

    await tester.tap(find.text('Register secure account'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back,'), findsOneWidget);
    expect(find.text('Akash Madhu'), findsOneWidget);
    expect(find.text('PATIENT DASHBOARD'), findsOneWidget);
  });

  testWidgets('doctor can sign in to the doctor console', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MedifixApp(controller: HealthAppController.seeded()),
    );

    await tester.tap(find.text('Doctor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in to dashboard'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Medifix Doctor Console'), findsOneWidget);
    expect(find.text('Add patient'), findsOneWidget);
    expect(find.text('Patients'), findsOneWidget);
  });

  testWidgets('hospital can sign in to the hospital portal', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MedifixApp(controller: HealthAppController.seeded()),
    );

    await tester.tap(find.text('Hospital'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in to dashboard'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Medifix Hospital Portal'), findsOneWidget);
    expect(find.text('Share Data'), findsOneWidget);
  });

  testWidgets('hospital portal navigation reaches share and patient views', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MedifixApp(controller: HealthAppController.seeded()),
    );

    await tester.tap(find.text('Hospital'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in to dashboard'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share Data').last);
    await tester.pumpAndSettle();
    expect(find.text('Hospital data sharing'), findsOneWidget);

    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    expect(find.text('Patient directory'), findsOneWidget);
  });

  testWidgets('auth screen does not overflow on a short mobile viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MedifixApp(controller: HealthAppController.seeded()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('doctor controller can add a patient and edit records', () async {
    final controller = HealthAppController.seeded();

    final loginMessage = await controller.login(
      'dr.luffy@medibridge.app',
      'Doctor@123',
      role: AccountRole.doctor,
    );
    expect(loginMessage, isNull);
    expect(controller.isDoctor, isTrue);

    final addPatientMessage = await controller.addPatientAsDoctor(
      fullName: 'Akash Madhu',
      email: 'akash@example.com',
      hospitalNetwork: 'Sree Buddha Medical Network',
      bloodGroup: 'A+',
      emergencyContact: 'Emergency Contact • +91 90000 00000',
    );
    expect(addPatientMessage, isNull);

    final createdPatient = controller.findPatientByEmail('akash@example.com');
    expect(createdPatient, isNotNull);
    expect(createdPatient!.profile.name, 'Akash Madhu');

    final saveRecordMessage = await controller.savePatientRecord(
      patientEmail: 'akash@example.com',
      existingRecord: null,
      title: 'Doctor consultation note',
      category: 'Visit Summary',
      source: 'Doctor Workstation',
      summary: 'The patient attended an initial consultation.',
      details: 'Vitals reviewed and treatment plan documented by the doctor.',
      status: 'Reviewed',
      standard: 'FHIR',
      tags: 'consultation, doctor-entry',
    );
    expect(saveRecordMessage, isNull);

    final updatedPatient = controller.findPatientByEmail('akash@example.com');
    expect(updatedPatient, isNotNull);
    expect(
      updatedPatient!.records.any(
        (record) => record.title == 'Doctor consultation note',
      ),
      isTrue,
    );
  });

  test('doctor can delete a patient', () async {
    final controller = HealthAppController.seeded();

    await controller.login(
      'dr.luffy@medibridge.app',
      'Doctor@123',
      role: AccountRole.doctor,
    );
    await controller.addPatientAsDoctor(
      fullName: 'Delete Me',
      email: 'deleteme@example.com',
      hospitalNetwork: 'Sree Buddha Medical Network',
      bloodGroup: 'AB+',
      emergencyContact: 'Emergency Contact • +91 82222 22222',
    );

    expect(controller.findPatientByEmail('deleteme@example.com'), isNotNull);

    final deleteMessage = await controller.deletePatientAsDoctor(
      'deleteme@example.com',
    );
    expect(deleteMessage, isNull);
    expect(controller.findPatientByEmail('deleteme@example.com'), isNull);
  });

  test('patient can update personal details and emergency contacts', () async {
    final controller = HealthAppController.seeded();
    await controller.login(
      'akash123@gmail.com',
      'Pass@123',
      role: AccountRole.patient,
    );

    final updateMessage = await controller.updateCurrentPatientProfile(
      name: 'Akash Updated',
      bloodGroup: 'A+',
      phone: '+91 97777 11111',
      address: 'Alappuzha, Kerala',
      allergies: 'Dust, Pollen',
      emergencyContacts: const [
        'Daniel Gomez • Husband • +91 99999 12345',
        'Maya Gomez • Daughter • +91 98888 99999',
      ],
    );
    expect(updateMessage, isNull);

    final patient = controller.findPatientByEmail('akash123@gmail.com');
    expect(patient, isNotNull);
    expect(patient!.profile.name, 'Akash Updated');
    expect(patient.profile.emergencyContacts.length, 2);
  });

  test('persistent storage reloads saved patients and records', () async {
    SharedPreferences.setMockInitialValues({});

    final firstController = await HealthAppController.createPersistent();
    final loginMessage = await firstController.login(
      'dr.luffy@medibridge.app',
      'Doctor@123',
      role: AccountRole.doctor,
    );
    expect(loginMessage, isNull);

    final addPatientMessage = await firstController.addPatientAsDoctor(
      fullName: 'Persistent Patient',
      email: 'persistent@example.com',
      hospitalNetwork: 'Sree Buddha Medical Network',
      bloodGroup: 'B+',
      emergencyContact: 'Emergency Contact • +91 81111 11111',
    );
    expect(addPatientMessage, isNull);

    final addRecordMessage = await firstController.savePatientRecord(
      patientEmail: 'persistent@example.com',
      existingRecord: null,
      title: 'Persistent record',
      category: 'Lab Report',
      source: 'Doctor Workstation',
      summary: 'Stored through local persistence.',
      details: 'This record should still exist after controller reload.',
      status: 'Reviewed',
      standard: 'FHIR',
      tags: 'persistent, test',
      attachments: [
        RecordAttachment(
          id: 'ATT-test',
          fileName: 'scan.png',
          mimeType: 'image/png',
          base64Data: base64Encode(List<int>.filled(16, 7)),
        ),
      ],
    );
    expect(addRecordMessage, isNull);

    final secondController = await HealthAppController.createPersistent();
    final reloadedPatient = secondController.findPatientByEmail(
      'persistent@example.com',
    );
    expect(reloadedPatient, isNotNull);
    expect(reloadedPatient!.profile.name, 'Persistent Patient');
    expect(
      reloadedPatient.records.any(
        (record) => record.title == 'Persistent record',
      ),
      isTrue,
    );
    final savedRecord = reloadedPatient.records.firstWhere(
      (record) => record.title == 'Persistent record',
    );
    expect(savedRecord.attachments, isNotEmpty);
    expect(savedRecord.attachments.first.fileName, 'scan.png');
  });

  test('hospital controller can share data to a patient record', () async {
    final controller = HealthAppController.seeded();

    final loginMessage = await controller.login(
      'records@greenvalleyhospital.com',
      'Hospital@123',
      role: AccountRole.hospital,
    );
    expect(loginMessage, isNull);
    expect(controller.isHospital, isTrue);

    final saveRecordMessage = await controller.savePatientRecord(
      patientEmail: 'akash123@gmail.com',
      existingRecord: null,
      title: 'Hospital discharge summary',
      category: 'Visit Summary',
      source: 'Green Valley Hospital',
      summary: 'Discharge summary sent from hospital portal.',
      details: 'Medication plan and follow-up instructions were shared.',
      status: 'Reviewed',
      standard: 'FHIR',
      tags: 'hospital-share, discharge',
    );
    expect(saveRecordMessage, isNull);

    final patient = controller.findPatientByEmail('akash123@gmail.com');
    expect(
      patient!.records.any(
        (record) => record.title == 'Hospital discharge summary',
      ),
      isTrue,
    );
  });

  test('hospital can add doctor with assigned patients', () async {
    final controller = HealthAppController.seeded();

    await controller.login(
      'records@greenvalleyhospital.com',
      'Hospital@123',
      role: AccountRole.hospital,
    );
    final message = await controller.addDoctorAsHospital(
      fullName: 'Dr. Anil Kumar',
      email: 'anil@greenvalleyhospital.com',
      specialty: 'Radiology',
      assignedPatientEmails: const ['akash123@gmail.com'],
    );
    expect(message, isNull);
    expect(
      controller.hospitalDoctors.any(
        (doctor) => doctor.email == 'anil@greenvalleyhospital.com',
      ),
      isTrue,
    );
  });
}
