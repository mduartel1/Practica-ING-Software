import Foundation
import Combine

@MainActor
final class AsistQRStore: ObservableObject {
    @Published private(set) var subjects: [SubjectItem]
    @Published private(set) var attendance: [AttendanceItem]
    @Published private(set) var activeSession: QRSession?
    private let defaults: UserDefaults?
    private let storageKey: String

    init(
        subjects: [SubjectItem] = SubjectItem.seed,
        attendance: [AttendanceItem] = AttendanceItem.seed,
        activeSession: QRSession? = nil,
        defaults: UserDefaults? = nil,
        storageKey: String = "asistqr.store.v1"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey

        if let snapshot = Self.loadSnapshot(defaults: defaults, storageKey: storageKey) {
            self.subjects = snapshot.subjects
            self.attendance = snapshot.attendance
            self.activeSession = snapshot.activeSession
        } else {
            self.subjects = subjects
            self.attendance = attendance
            self.activeSession = activeSession
        }
    }

    static func live() -> AsistQRStore {
        AsistQRStore(defaults: .standard)
    }

    func createSubject(name: String, group: String, room: String) -> Bool {
        let trimmedName = name.trimmed
        let trimmedGroup = group.trimmed
        let trimmedRoom = room.trimmed

        guard !trimmedName.isEmpty, !trimmedGroup.isEmpty, !trimmedRoom.isEmpty else {
            return false
        }

        subjects.append(
            SubjectItem(
                name: trimmedName,
                detail: "\(trimmedGroup) · \(trimmedRoom)"
            )
        )
        persist()
        return true
    }

    func enableSession(for subject: SubjectItem, expiryMinutes: Int) {
        activeSession = QRSession(
            subjectName: subject.name,
            subjectDetail: subject.detail,
            code: QRSession.makeCode(for: subject.name),
            expiresAt: Date().addingTimeInterval(TimeInterval(expiryMinutes * 60)),
            isActive: true
        )
        persist()
    }

    func disableSession() {
        guard var session = activeSession else { return }
        session.isActive = false
        activeSession = session
        persist()
    }

    @discardableResult
    func registerAttendance(sessionCode: String, studentName: String = "Mario Duarte") -> AttendanceRegistrationResult {
        let code = sessionCode.trimmed

        guard !code.isEmpty else {
            return .failure("Introduce un codigo de sesion.")
        }

        guard let session = activeSession, session.isActive else {
            return .failure("No hay una sesion QR activa.")
        }

        guard session.code == code else {
            return .failure("El codigo no corresponde a la sesion activa.")
        }

        guard session.expiresAt >= Date() else {
            return .failure("La sesion QR ha caducado.")
        }

        if attendance.contains(where: { $0.sessionCode == code && $0.studentName == studentName }) {
            return .failure("La asistencia ya estaba registrada.")
        }

        let record = AttendanceItem(
            title: session.subjectName,
            subtitle: studentName,
            time: Date().formatted(date: .omitted, time: .shortened),
            status: "Presente",
            subjectName: session.subjectName,
            studentName: studentName,
            sessionCode: code
        )
        attendance.insert(record, at: 0)
        persist()
        return .success("Asistencia registrada correctamente.")
    }

    func records(subject: String? = nil, student: String? = nil, period: Period? = nil, referenceDate: Date = Date()) -> [AttendanceItem] {
        attendance.filter { item in
            let subjectMatches = subject == nil || subject == "Todas" || item.subjectName == subject
            let studentMatches = student == nil || student == "Todos" || item.studentName == student
            let periodMatches = period?.contains(item.timestamp, referenceDate: referenceDate) ?? true
            return subjectMatches && studentMatches && periodMatches
        }
    }

    func attendanceCSV(subject: String? = nil, student: String? = nil) -> String {
        let header = ["Asignatura", "Alumno", "Hora", "Estado", "Codigo QR"]
        let rows = records(subject: subject, student: student).map { item in
            [item.subjectName, item.studentName, item.time, item.status, item.sessionCode]
        }

        return ([header] + rows)
            .map { row in row.map(Self.csvField).joined(separator: ",") }
            .joined(separator: "\n")
    }

    private nonisolated static func csvField(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private func persist() {
        guard let defaults else { return }
        let snapshot = AsistQRSnapshot(
            subjects: subjects,
            attendance: attendance,
            activeSession: activeSession
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private static func loadSnapshot(defaults: UserDefaults?, storageKey: String) -> AsistQRSnapshot? {
        guard let data = defaults?.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(AsistQRSnapshot.self, from: data)
    }
}

private struct AsistQRSnapshot: Codable {
    let subjects: [SubjectItem]
    let attendance: [AttendanceItem]
    let activeSession: QRSession?
}

struct QRSession: Codable, Equatable {
    let subjectName: String
    let subjectDetail: String
    let code: String
    let expiresAt: Date
    var isActive: Bool

    static func makeCode(for subjectName: String) -> String {
        let slug = subjectName
            .uppercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .prefix(2)
            .map(String.init)
            .joined(separator: "-")
        return "ASISTQR-\(slug)-01"
    }
}

enum AttendanceRegistrationResult: Equatable {
    case success(String)
    case failure(String)

    var title: String {
        switch self {
        case .success:
            return "Asistencia registrada"
        case .failure:
            return "No se pudo registrar"
        }
    }

    var message: String {
        switch self {
        case .success(let message), .failure(let message):
            return message
        }
    }

    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
