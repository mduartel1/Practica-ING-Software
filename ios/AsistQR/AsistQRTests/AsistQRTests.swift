//
//  AsistQRTests.swift
//  AsistQRTests
//
//  Created by Mario Duarte Lanseros on 2/3/26.
//

import Testing
import Foundation
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

    @MainActor
    @Test func attendanceCSVIncludesHeadersAndFilteredRows() async throws {
        let records = [
            AttendanceItem(
                title: "Laboratorio de Software",
                subtitle: "Mario Duarte",
                time: "08:30",
                status: "Presente",
                sessionCode: "ASISTQR-LAB-01"
            ),
            AttendanceItem(
                title: "Bases de Datos",
                subtitle: "Ana Perez",
                time: "10:15",
                status: "Tarde",
                sessionCode: "ASISTQR-BD-01"
            )
        ]
        let store = AsistQRStore(subjects: [], attendance: records)

        let csv = store.attendanceCSV(subject: "Laboratorio de Software", student: "Todos")

        #expect(csv.contains("Asignatura,Alumno,Hora,Estado,Codigo QR"))
        #expect(csv.contains("Laboratorio de Software,Mario Duarte,08:30,Presente,ASISTQR-LAB-01"))
        #expect(!csv.contains("Bases de Datos"))
    }

    @MainActor
    @Test func attendanceCSVEscapesCommaAndQuoteFields() async throws {
        let records = [
            AttendanceItem(
                title: "Bases, Datos",
                subtitle: "Ana \"A\" Perez",
                time: "10:15",
                status: "Presente",
                sessionCode: "ASISTQR-BD-01"
            )
        ]
        let store = AsistQRStore(subjects: [], attendance: records)

        let csv = store.attendanceCSV()

        #expect(csv.contains("\"Bases, Datos\",\"Ana \"\"A\"\" Perez\",10:15,Presente,ASISTQR-BD-01"))
    }

    @MainActor
    @Test func persistedStoreRestoresSubjectsSessionAndAttendance() async throws {
        let suiteName = "AsistQRTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let subject = SubjectItem(name: "Arquitectura", detail: "Grupo D · Aula 9")
        let store = AsistQRStore(subjects: [subject], attendance: [], defaults: defaults)
        store.enableSession(for: subject, expiryMinutes: 15)
        let code = try #require(store.activeSession?.code)
        let result = store.registerAttendance(sessionCode: code, studentName: "Laura Martin")

        let restored = AsistQRStore(subjects: [], attendance: [], defaults: defaults)

        #expect(result.isSuccess)
        #expect(restored.subjects == [subject])
        #expect(restored.activeSession?.code == code)
        #expect(restored.activeSession?.isActive == true)
        #expect(restored.attendance.count == 1)
        #expect(restored.attendance.first?.studentName == "Laura Martin")
        #expect(restored.attendance.first?.subjectName == "Arquitectura")
    }

}
