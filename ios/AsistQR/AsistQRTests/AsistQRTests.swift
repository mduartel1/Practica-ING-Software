//
//  AsistQRTests.swift
//  AsistQRTests
//
//  Created by Mario Duarte Lanseros on 2/3/26.
//

import Testing
@testable import AsistQR

struct AsistQRTests {

    @MainActor
    @Test func createSubjectAddsValidCourse() async throws {
        let store = AsistQRStore(subjects: [], attendance: [])

        let created = store.createSubject(name: "  Ingenieria de Software  ", group: "Grupo C", room: "Aula 4")

        #expect(created)
        #expect(store.subjects.count == 1)
        #expect(store.subjects.first?.name == "Ingenieria de Software")
        #expect(store.subjects.first?.detail == "Grupo C · Aula 4")
    }

    @MainActor
    @Test func createSubjectRejectsIncompleteData() async throws {
        let store = AsistQRStore(subjects: [], attendance: [])

        let created = store.createSubject(name: "", group: "Grupo A", room: "Aula 1")

        #expect(!created)
        #expect(store.subjects.isEmpty)
    }

    @MainActor
    @Test func enabledSessionAcceptsMatchingQrCodeOnce() async throws {
        let subject = SubjectItem(name: "Laboratorio de Software", detail: "Grupo A · Aula 2")
        let store = AsistQRStore(subjects: [subject], attendance: [])

        store.enableSession(for: subject, expiryMinutes: 15)
        let code = try #require(store.activeSession?.code)

        let firstResult = store.registerAttendance(sessionCode: code, studentName: "Mario Duarte")
        let duplicateResult = store.registerAttendance(sessionCode: code, studentName: "Mario Duarte")

        #expect(firstResult.isSuccess)
        #expect(!duplicateResult.isSuccess)
        #expect(store.attendance.count == 1)
        #expect(store.attendance.first?.subjectName == "Laboratorio de Software")
        #expect(store.attendance.first?.studentName == "Mario Duarte")
    }

    @MainActor
    @Test func disabledSessionRejectsAttendance() async throws {
        let subject = SubjectItem(name: "Bases de Datos", detail: "Grupo B · Aula 5")
        let store = AsistQRStore(subjects: [subject], attendance: [])

        store.enableSession(for: subject, expiryMinutes: 15)
        let code = try #require(store.activeSession?.code)
        store.disableSession()

        let result = store.registerAttendance(sessionCode: code, studentName: "Ana Perez")

        #expect(!result.isSuccess)
        #expect(store.attendance.isEmpty)
    }

}
