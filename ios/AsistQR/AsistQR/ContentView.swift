//
//  ContentView.swift
//  AsistQR
//
//  Created by Mario Duarte Lanseros on 2/3/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = AsistQRStore.live()

    var body: some View {
        AuthLandingView()
            .environmentObject(store)
    }

}

struct AttendanceListView: View {
    @EnvironmentObject private var store: AsistQRStore
    @State private var selectedSubject = "Todas"
    @State private var selectedPeriod: Period = .today

    private var subjects: [String] {
        ["Todas"] + store.subjects.map(\.name)
    }

    private var items: [AttendanceItem] {
        store.records(subject: selectedSubject, student: store.currentUser?.name, period: selectedPeriod)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.12),
                    Color(red: 0.04, green: 0.08, blue: 0.18),
                    Color(red: 0.10, green: 0.06, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mi asistencia")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Historico personal por asignatura")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                subjectSelector

                HStack(spacing: 10) {
                    periodChip(title: "Hoy", period: .today)
                    periodChip(title: "Semana", period: .week)
                    periodChip(title: "Mes", period: .month)
                }

                ScrollView {
                    VStack(spacing: 14) {
                        if items.isEmpty {
                            emptyState
                        } else {
                            ForEach(items) { item in
                                attendanceRow(item: item)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text("Sin registros para este filtro")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.08))
        )
    }

    @ViewBuilder
    private func periodChip(title: String, period: Period) -> some View {
        Button {
            selectedPeriod = period
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(selectedPeriod == period ? Color.black.opacity(0.85) : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selectedPeriod == period ? Color(red: 0.90, green: 0.87, blue: 0.35) : .white.opacity(0.12))
                )
        }
    }

    @ViewBuilder
    private func attendanceRow(item: AttendanceItem) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(item.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(item.time)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(item.status)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(statusColor(for: item.status))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "Presente":
            return Color(red: 0.48, green: 0.90, blue: 0.63)
        case "Tarde":
            return Color(red: 0.98, green: 0.71, blue: 0.32)
        default:
            return Color(red: 0.62, green: 0.66, blue: 0.98)
        }
    }

    private var subjectSelector: some View {
        Menu {
            ForEach(subjects, id: \.self) { subject in
                Button(subject) { selectedSubject = subject }
            }
        } label: {
            HStack {
                Text("Asignatura: \(selectedSubject)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.12))
            )
        }
    }
}

struct AttendanceItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let time: String
    let status: String
    let subjectName: String
    let studentName: String
    let sessionCode: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        time: String,
        status: String,
        subjectName: String? = nil,
        studentName: String? = nil,
        sessionCode: String = "",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.time = time
        self.status = status
        self.subjectName = subjectName ?? title
        self.studentName = studentName ?? subtitle
        self.sessionCode = sessionCode
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case time
        case status
        case subjectName
        case studentName
        case sessionCode
        case timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        time = try container.decode(String.self, forKey: .time)
        status = try container.decode(String.self, forKey: .status)
        subjectName = try container.decode(String.self, forKey: .subjectName)
        studentName = try container.decode(String.self, forKey: .studentName)
        sessionCode = try container.decode(String.self, forKey: .sessionCode)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
    }
}

extension AttendanceItem {
    nonisolated static let seed: [AttendanceItem] = [
        AttendanceItem(
            title: "Laboratorio de Software",
            subtitle: "Mario Duarte",
            time: "08:30",
            status: "Presente",
            sessionCode: "ASISTQR-LABORATORIO-SOFTWARE-01"
        ),
        AttendanceItem(
            title: "Bases de Datos",
            subtitle: "Ana Perez",
            time: "10:15",
            status: "Tarde",
            sessionCode: "ASISTQR-BASES-DATOS-01"
        ),
        AttendanceItem(
            title: "Redes II",
            subtitle: "Jose Lopez",
            time: "12:00",
            status: "Presente",
            sessionCode: "ASISTQR-REDES-II-01"
        )
    ]
}

enum Period {
    case today
    case week
    case month
}

extension Period {
    func contains(_ date: Date, referenceDate: Date = Date(), calendar: Calendar = .current) -> Bool {
        switch self {
        case .today:
            return calendar.isDate(date, inSameDayAs: referenceDate)
        case .week:
            let dateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            let referenceComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
            return dateComponents.yearForWeekOfYear == referenceComponents.yearForWeekOfYear
                && dateComponents.weekOfYear == referenceComponents.weekOfYear
        case .month:
            let dateComponents = calendar.dateComponents([.year, .month], from: date)
            let referenceComponents = calendar.dateComponents([.year, .month], from: referenceDate)
            return dateComponents.year == referenceComponents.year
                && dateComponents.month == referenceComponents.month
        }
    }
}

#Preview {
    ContentView()
}
