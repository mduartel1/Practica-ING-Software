//
//  ContentView.swift
//  AsistQR
//
//  Created by Mario Duarte Lanseros on 2/3/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        AuthLandingView()
    }

}

struct AttendanceListView: View {
    private let items: [AttendanceItem] = [
        AttendanceItem(title: "Laboratorio de Software", subtitle: "Grupo A · Aula 2", time: "08:30", status: "Presente"),
        AttendanceItem(title: "Bases de Datos", subtitle: "Grupo B · Aula 5", time: "10:15", status: "Tarde"),
        AttendanceItem(title: "Redes II", subtitle: "Grupo A · Aula 1", time: "12:00", status: "Presente"),
        AttendanceItem(title: "Ingenieria de Software", subtitle: "Grupo C · Aula 4", time: "13:45", status: "Justificado")
    ]
    private let subjects = ["Todas", "Laboratorio de Software", "Bases de Datos", "Redes II"]
    @State private var selectedSubject = "Todas"
    @State private var selectedPeriod: Period = .today

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
                        ForEach(items) { item in
                            attendanceRow(item: item)
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

struct AttendanceItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let time: String
    let status: String
}

enum Period {
    case today
    case week
    case month
}

#Preview {
    ContentView()
}
