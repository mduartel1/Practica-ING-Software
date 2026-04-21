import SwiftUI
import CoreImage.CIFilterBuiltins

struct AuthLandingView: View {
    @State private var role: UserRole = .student

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.07, blue: 0.12),
                        Color(red: 0.05, green: 0.10, blue: 0.22),
                        Color(red: 0.12, green: 0.06, blue: 0.22)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AsistQR")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Registro de asistencia por QR")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    rolePicker

                    VStack(spacing: 14) {
                        NavigationLink {
                            LoginView(role: role)
                        } label: {
                            actionButton(title: "Iniciar sesion", filled: true)
                        }

                        NavigationLink {
                            RegisterView(role: role)
                        } label: {
                            actionButton(title: "Registrarse", filled: false)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        infoRow(icon: "qrcode", text: "Escanear QR para registrar asistencia")
                        infoRow(icon: "person.2", text: "Registro e inicio de sesion")
                        infoRow(icon: "chart.bar.xaxis", text: "Consulta de historicos y exportacion")
                    }
                    .padding(.top, 10)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 20)
            }
        }
    }

    private var rolePicker: some View {
        HStack(spacing: 10) {
            roleChip(title: "Alumno", role: .student)
            roleChip(title: "Profesor", role: .teacher)
        }
    }

    @ViewBuilder
    private func roleChip(title: String, role: UserRole) -> some View {
        Button {
            self.role = role
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(self.role == role ? Color.black.opacity(0.85) : .white)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(self.role == role ? Color(red: 0.90, green: 0.87, blue: 0.35) : .white.opacity(0.12))
                )
        }
    }

    @ViewBuilder
    private func actionButton(title: String, filled: Bool) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(filled ? Color(red: 0.90, green: 0.87, blue: 0.35) : .white.opacity(0.12))
            )
            .foregroundStyle(filled ? Color.black.opacity(0.9) : .white)
    }

    @ViewBuilder
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct LoginView: View {
    let role: UserRole
    @EnvironmentObject private var store: AsistQRStore
    @State private var email = ""
    @State private var password = ""
    @State private var goHome = false
    @State private var goRegister = false
    @State private var errorText: String?

    var body: some View {
        AuthFormView(
            title: "Iniciar sesion",
            subtitle: role == .teacher ? "Acceso para profesores" : "Acceso para alumnos",
            primaryLabel: "Entrar",
            secondaryText: "No tienes cuenta?",
            secondaryAction: "Registrarse",
            errorMessage: errorText
        ) {
            Group {
                TextField("Correo institucional", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Contrasena", text: $password)
            }
        } primaryAction: {
            errorText = nil
            let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
            guard !trimmedEmail.isEmpty else {
                errorText = "Introduce tu correo institucional."
                return
            }
            guard trimmedEmail.contains("@") else {
                errorText = "El correo no tiene un formato valido."
                return
            }
            guard !password.isEmpty else {
                errorText = "Introduce tu contrasena."
                return
            }
            let name = String(trimmedEmail.split(separator: "@").first ?? Substring(trimmedEmail))
            store.loginUser(name: name.isEmpty ? trimmedEmail : name, email: trimmedEmail, role: role)
            goHome = true
        } secondaryActionHandler: {
            goRegister = true
        }
        .navigationDestination(isPresented: $goHome) {
            role == .teacher ? AnyView(ProfessorHomeView()) : AnyView(StudentHomeView())
        }
        .navigationDestination(isPresented: $goRegister) {
            RegisterView(role: role)
        }
    }
}

struct RegisterView: View {
    let role: UserRole
    @EnvironmentObject private var store: AsistQRStore
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var goHome = false
    @State private var goLogin = false
    @State private var errorText: String?

    var body: some View {
        AuthFormView(
            title: "Registrarse",
            subtitle: role == .teacher ? "Registro de profesor" : "Registro de alumno",
            primaryLabel: "Registrar",
            secondaryText: "Ya tienes cuenta?",
            secondaryAction: "Iniciar sesion",
            errorMessage: errorText
        ) {
            Group {
                TextField("Nombre completo", text: $name)
                TextField("Correo institucional", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Contrasena", text: $password)
            }
        } primaryAction: {
            errorText = nil
            let trimmedName = name.trimmingCharacters(in: .whitespaces)
            let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
            guard !trimmedName.isEmpty else {
                errorText = "Introduce tu nombre completo."
                return
            }
            guard !trimmedEmail.isEmpty, trimmedEmail.contains("@") else {
                errorText = "Introduce un correo institucional valido."
                return
            }
            guard password.count >= 6 else {
                errorText = "La contrasena debe tener al menos 6 caracteres."
                return
            }
            store.loginUser(name: trimmedName, email: trimmedEmail, role: role)
            goHome = true
        } secondaryActionHandler: {
            goLogin = true
        }
        .navigationDestination(isPresented: $goHome) {
            role == .teacher ? AnyView(ProfessorHomeView()) : AnyView(StudentHomeView())
        }
        .navigationDestination(isPresented: $goLogin) {
            LoginView(role: role)
        }
    }
}

struct AuthFormView<Fields: View>: View {
    let title: String
    let subtitle: String
    let primaryLabel: String
    let secondaryText: String
    let secondaryAction: String
    let fields: Fields
    let primaryAction: () -> Void
    let secondaryActionHandler: () -> Void
    var errorMessage: String? = nil

    init(
        title: String,
        subtitle: String,
        primaryLabel: String,
        secondaryText: String,
        secondaryAction: String,
        errorMessage: String? = nil,
        @ViewBuilder fields: () -> Fields,
        primaryAction: @escaping () -> Void,
        secondaryActionHandler: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.primaryLabel = primaryLabel
        self.secondaryText = secondaryText
        self.secondaryAction = secondaryAction
        self.errorMessage = errorMessage
        self.fields = fields()
        self.primaryAction = primaryAction
        self.secondaryActionHandler = secondaryActionHandler
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.12),
                    Color(red: 0.05, green: 0.10, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Introduce los datos requeridos")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }

                VStack(spacing: 14) {
                    fields
                        .textFieldStyle(.plain)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.white.opacity(0.12))
                        )
                        .foregroundStyle(.white)
                        .tint(Color(red: 0.90, green: 0.87, blue: 0.35))
                }

                if let errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(Color(red: 0.98, green: 0.50, blue: 0.45))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 0.98, green: 0.50, blue: 0.45).opacity(0.12))
                    )
                }

                Button {
                    primaryAction()
                } label: {
                    Text(primaryLabel)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(red: 0.90, green: 0.87, blue: 0.35))
                        )
                        .foregroundStyle(Color.black.opacity(0.9))
                }

                HStack(spacing: 6) {
                    Text(secondaryText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Button {
                        secondaryActionHandler()
                    } label: {
                        Text(secondaryAction)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 0.90, green: 0.87, blue: 0.35))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
    }
}

struct StudentHomeView: View {
    @EnvironmentObject private var store: AsistQRStore
    @State private var goLanding = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.07, blue: 0.12),
                    Color(red: 0.05, green: 0.10, blue: 0.22),
                    Color(red: 0.12, green: 0.06, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.currentUser?.name ?? "Alumno")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Panel de asistencia")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    Button {
                        store.logoutUser()
                        goLanding = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                NavigationLink {
                    QRScannerView()
                } label: {
                    primaryCard(title: "Escanear QR", subtitle: "Registrar asistencia")
                }

                NavigationLink {
                    AttendanceListView()
                } label: {
                    secondaryCard(title: "Mi asistencia", subtitle: "Historico personal")
                }

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $goLanding) {
            AuthLandingView()
                .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    private func primaryCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Text(subtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.6))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.90, green: 0.87, blue: 0.35))
        )
        .foregroundStyle(Color.black.opacity(0.9))
    }

    @ViewBuilder
    private func secondaryCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.12))
        )
    }
}

struct ProfessorHomeView: View {
    @EnvironmentObject private var store: AsistQRStore
    @State private var showingExport = false
    @State private var goLanding = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.12),
                    Color(red: 0.04, green: 0.09, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.currentUser?.name ?? "Profesor")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Gestion de asignaturas y sesiones")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    Button {
                        store.logoutUser()
                        goLanding = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                NavigationLink {
                    SubjectsListView()
                } label: {
                    primaryRow(title: "Asignaturas", subtitle: "Crear y administrar")
                }

                NavigationLink {
                    SessionControlView()
                } label: {
                    secondaryRow(title: "Sesion activa", subtitle: "Habilitar o deshabilitar QR")
                }

                NavigationLink {
                    ProfessorHistoryView()
                } label: {
                    secondaryRow(title: "Historico", subtitle: "Por asignatura o alumno")
                }

                Button {
                    showingExport = true
                } label: {
                    secondaryRow(title: "Exportar CSV", subtitle: "Descargar historico")
                }

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingExport) {
            CSVExportView(csvText: store.attendanceCSV())
        }
        .navigationDestination(isPresented: $goLanding) {
            AuthLandingView()
                .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    private func primaryRow(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.6))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.90, green: 0.87, blue: 0.35))
        )
        .foregroundStyle(Color.black.opacity(0.9))
    }

    @ViewBuilder
    private func secondaryRow(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.12))
        )
        .foregroundStyle(.white)
    }
}

struct SubjectsListView: View {
    @EnvironmentObject private var store: AsistQRStore
    @State private var subjectToDelete: SubjectItem?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.12),
                    Color(red: 0.04, green: 0.09, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Asignaturas")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("\(store.subjects.count) asignaturas")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    NavigationLink {
                        CreateSubjectView()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.9))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(red: 0.90, green: 0.87, blue: 0.35)))
                    }
                }

                if store.subjects.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Aun no hay asignaturas")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("Pulsa + para crear una")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.06))
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(store.subjects) { subject in
                                NavigationLink {
                                    SubjectDetailView(subject: subject)
                                } label: {
                                    subjectRow(subject: subject)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        subjectToDelete = subject
                                    } label: {
                                        Label("Eliminar asignatura", systemImage: "trash")
                                    }
                                }
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
        .alert("Eliminar asignatura", isPresented: Binding(
            get: { subjectToDelete != nil },
            set: { if !$0 { subjectToDelete = nil } }
        )) {
            Button("Eliminar", role: .destructive) {
                if let s = subjectToDelete {
                    store.deleteSubject(id: s.id)
                }
                subjectToDelete = nil
            }
            Button("Cancelar", role: .cancel) { subjectToDelete = nil }
        } message: {
            Text("Se eliminara \"\(subjectToDelete?.name ?? "")\" y no se podra recuperar.")
        }
    }

    @ViewBuilder
    private func subjectRow(subject: SubjectItem) -> some View {
        let count = store.attendanceCount(for: subject.name)
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(subject.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subject.detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Color(red: 0.90, green: 0.87, blue: 0.35))
                    )
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.12))
        )
    }
}

struct CreateSubjectView: View {
    @EnvironmentObject private var store: AsistQRStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var group = ""
    @State private var room = ""
    @State private var errorText: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.12),
                    Color(red: 0.04, green: 0.09, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Crear asignatura")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Rellena los datos de la nueva asignatura")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }

                VStack(spacing: 14) {
                    labeledField(label: "Nombre", placeholder: "Ej. Laboratorio de Software", text: $name)
                    labeledField(label: "Grupo", placeholder: "Ej. Grupo A", text: $group)
                    labeledField(label: "Aula", placeholder: "Ej. Aula 204", text: $room)
                }

                if let errorText {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                        Text(errorText)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(Color(red: 0.98, green: 0.71, blue: 0.32))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 0.98, green: 0.71, blue: 0.32).opacity(0.12))
                    )
                }

                Button {
                    if store.createSubject(name: name, group: group, room: room) {
                        dismiss()
                    } else {
                        errorText = "Completa nombre, grupo y aula."
                    }
                } label: {
                    Text("Guardar asignatura")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(red: 0.90, green: 0.87, blue: 0.35))
                        )
                        .foregroundStyle(Color.black.opacity(0.9))
                }

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func labeledField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .tint(Color(red: 0.90, green: 0.87, blue: 0.35))
                .padding(.vertical, 13)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.20), lineWidth: 1)
                        )
                )
        }
    }
}

struct SubjectDetailView: View {
    let subject: SubjectItem
    @EnvironmentObject private var store: AsistQRStore
    @State private var showAddStudent = false
    @State private var newStudentName = ""

    private var liveSubject: SubjectItem {
        store.subjects.first(where: { $0.id == subject.id }) ?? subject
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.12),
                    Color(red: 0.04, green: 0.09, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(liveSubject.name)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(liveSubject.detail)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    NavigationLink {
                        SessionControlView(subject: liveSubject)
                    } label: {
                        actionRow(title: "Habilitar QR", subtitle: "Generar QR temporal para la sesion")
                    }

                    NavigationLink {
                        ProfessorHistoryView()
                    } label: {
                        actionRow(title: "Ver historico", subtitle: "Por asignatura y alumno")
                    }

                    studentsSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddStudent) {
            addStudentSheet
        }
    }

    private var studentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Alumnos matriculados")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(liveSubject.students.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(red: 0.90, green: 0.87, blue: 0.35)))
                Button {
                    showAddStudent = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.90, green: 0.87, blue: 0.35))
                }
            }

            if liveSubject.students.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Aun no hay alumnos. Pulsa + para anadir.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.06))
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(liveSubject.students.enumerated()), id: \.offset) { idx, student in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.5))
                            Text(student)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                            Button {
                                store.removeStudent(student, from: liveSubject.id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color(red: 0.95, green: 0.35, blue: 0.35).opacity(0.8))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        if idx < liveSubject.students.count - 1 {
                            Divider().overlay(Color.white.opacity(0.08))
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.09))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.white.opacity(0.10), lineWidth: 1)
                        )
                )
            }
        }
    }

    private var addStudentSheet: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color(red: 0.90, green: 0.87, blue: 0.35))
                Text("Anadir alumno")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Introduce el nombre del alumno")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            TextField("Nombre completo", text: $newStudentName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.05))
                )

            Button {
                let trimmed = newStudentName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                store.addStudent(trimmed, to: liveSubject.id)
                newStudentName = ""
                showAddStudent = false
            } label: {
                Text("Anadir")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(red: 0.90, green: 0.87, blue: 0.35))
                    )
                    .foregroundStyle(Color.black.opacity(0.9))
            }

            Button { showAddStudent = false } label: {
                Text("Cancelar")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .onDisappear { newStudentName = "" }
    }

    @ViewBuilder
    private func actionRow(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.6))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.90, green: 0.87, blue: 0.35))
        )
        .foregroundStyle(Color.black.opacity(0.9))
    }
}

struct SessionControlView: View {
    @EnvironmentObject private var store: AsistQRStore
    let subject: SubjectItem?

    @State private var expiryMinutes = 15
    @State private var timeRemaining: TimeInterval = 0
    @State private var countdownTimer: Timer?

    init(subject: SubjectItem? = nil) {
        self.subject = subject
    }

    private var selectedSubject: SubjectItem? {
        subject ?? store.subjects.first
    }

    private var session: QRSession? {
        store.activeSession
    }

    private var countdownColor: Color {
        if timeRemaining > 120 { return Color(red: 0.48, green: 0.90, blue: 0.63) }
        if timeRemaining > 30 { return Color(red: 0.98, green: 0.71, blue: 0.32) }
        return Color(red: 0.95, green: 0.35, blue: 0.35)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.12),
                    Color(red: 0.04, green: 0.09, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Sesion activa")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(selectedSubject?.name ?? "Sin asignaturas")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 10) {
                    Text(session?.isActive == true ? "QR habilitado" : "QR deshabilitado")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(session?.isActive == true ? Color(red: 0.48, green: 0.90, blue: 0.63) : .white.opacity(0.6))
                    Spacer()
                    if session?.isActive == true && timeRemaining > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 12, weight: .semibold))
                            Text(formatCountdown(timeRemaining))
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        }
                        .foregroundStyle(countdownColor)
                    } else {
                        Text("Caduca en \(expiryMinutes) min")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.08))
                        .frame(height: 260)
                    VStack(spacing: 12) {
                        if let session, session.isActive {
                            QRCodeImageView(code: session.code)
                                .frame(width: 200, height: 200)
                                .padding(4)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            Image(systemName: "qrcode")
                                .font(.system(size: 70, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.25))
                            Text("QR no generado")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        if let selectedSubject {
                            store.enableSession(for: selectedSubject, expiryMinutes: expiryMinutes)
                            startCountdown()
                        }
                    } label: {
                        actionButton(title: "Habilitar QR", filled: true)
                    }

                    Button {
                        store.disableSession()
                        stopCountdown()
                    } label: {
                        actionButton(title: "Deshabilitar QR", filled: false)
                    }
                }

                HStack(spacing: 10) {
                    Text("Caducidad")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Stepper("", value: $expiryMinutes, in: 1...120, step: 1)
                        .labelsHidden()
                }
                .padding(.top, 6)

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { restoreCountdownIfNeeded() }
        .onDisappear { stopCountdown() }
    }

    private func formatCountdown(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func startCountdown() {
        stopCountdown()
        updateTimeRemaining()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTimeRemaining()
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func updateTimeRemaining() {
        guard let expiresAt = store.activeSession?.expiresAt else {
            timeRemaining = 0
            return
        }
        timeRemaining = max(0, expiresAt.timeIntervalSinceNow)
        if timeRemaining == 0 {
            stopCountdown()
            if store.activeSession?.isActive == true {
                store.disableSession()
            }
        }
    }

    private func restoreCountdownIfNeeded() {
        guard store.activeSession?.isActive == true else { return }
        startCountdown()
    }

    @ViewBuilder
    private func actionButton(title: String, filled: Bool) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(filled ? Color(red: 0.90, green: 0.87, blue: 0.35) : .white.opacity(0.12))
            )
            .foregroundStyle(filled ? Color.black.opacity(0.9) : .white)
    }
}

struct ProfessorHistoryView: View {
    @EnvironmentObject private var store: AsistQRStore
    @State private var selectedSubject = "Todas"
    @State private var selectedStudent = "Todos"
    @State private var showingExport = false

    private var subjectOptions: [String] {
        ["Todas"] + store.subjects.map(\.name)
    }

    private var studentOptions: [String] {
        let names = Set(store.attendance.map(\.studentName)).sorted()
        return ["Todos"] + names
    }

    private var items: [AttendanceItem] {
        store.records(subject: selectedSubject, student: selectedStudent)
    }

    private var exportCSV: String {
        store.attendanceCSV(subject: selectedSubject, student: selectedStudent)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.12),
                    Color(red: 0.04, green: 0.09, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text("Historico")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                VStack(spacing: 10) {
                    filterMenu(title: "Asignatura", selection: $selectedSubject, options: subjectOptions)
                    filterMenu(title: "Alumno", selection: $selectedStudent, options: studentOptions)
                }

                ScrollView {
                    VStack(spacing: 12) {
                        if items.isEmpty {
                            Text("Sin registros para este filtro")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.white.opacity(0.08))
                                )
                        } else {
                            ForEach(items) { item in
                                attendanceRow(item: item)
                            }
                        }
                    }
                }

                Button {
                    showingExport = true
                } label: {
                    Text("Exportar CSV")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(red: 0.90, green: 0.87, blue: 0.35))
                        )
                        .foregroundStyle(Color.black.opacity(0.9))
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExport) {
            CSVExportView(csvText: exportCSV)
        }
    }

    @ViewBuilder
    private func filterMenu(title: String, selection: Binding<String>, options: [String]) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { selection.wrappedValue = option }
            }
        } label: {
            HStack {
                Text("\(title): \(selection.wrappedValue)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
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

    @ViewBuilder
    private func attendanceRow(item: AttendanceItem) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(item.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(item.time)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(item.status)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(statusColor(for: item.status))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
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
}

struct CSVExportView: View {
    let csvText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Vista previa CSV")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                ScrollView {
                    Text(csvText)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black.opacity(0.05))
                        )
                }

                ShareLink(item: csvText) {
                    Text("Compartir CSV")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(red: 0.90, green: 0.87, blue: 0.35))
                        )
                        .foregroundStyle(Color.black.opacity(0.9))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 18)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct QRCodeImageView: View {
    let code: String

    var body: some View {
        if let image = makeQRImage(from: code) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            Image(systemName: "qrcode")
                .font(.system(size: 70))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func makeQRImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct SubjectItem: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let detail: String
    var students: [String]

    init(id: UUID = UUID(), name: String, detail: String, students: [String] = []) {
        self.id = id
        self.name = name
        self.detail = detail
        self.students = students
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        detail = try c.decode(String.self, forKey: .detail)
        students = (try? c.decodeIfPresent([String].self, forKey: .students)) ?? []
    }
}

extension SubjectItem {
    nonisolated static let seed: [SubjectItem] = [
        SubjectItem(name: "Laboratorio de Software", detail: "Grupo A · Aula 2"),
        SubjectItem(name: "Bases de Datos", detail: "Grupo B · Aula 5"),
        SubjectItem(name: "Redes II", detail: "Grupo A · Aula 1")
    ]
}

#Preview {
    AuthLandingView()
        .environmentObject(AsistQRStore())
}
