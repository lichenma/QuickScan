import SwiftUI
import Combine
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseAuth

struct SignInView: View {
    @State var pushActive = false
    @ObservedObject private var viewModel: SignInViewModel
    
    init(state: AppState) {
        self.viewModel = SignInViewModel(authAPI: AuthService(), state: state)
    }
    
    var body: some View {
        VStack {
            NavigationLink(destination: HomeView(state: viewModel.state),
                           isActive: self.$pushActive) {
              EmptyView()
            }.hidden()
            VStack(alignment: .leading, spacing: 30) {
                Text("Log in")
                    .modifier(TextModifier(font: UIConfiguration.titleFont,
                                           color: UIConfiguration.tintColor))
                    .padding(.leading, 25)
                VStack(alignment: .center, spacing: 30) {
                    VStack(alignment: .center, spacing: 25) {
                        CustomTextField(placeHolderText: "E-mail",
                                      text: $viewModel.email)
                        CustomTextField(placeHolderText: "Password",
                                      text: $viewModel.password,
                                      isPasswordType: true)
                    }.padding(.horizontal, 25)
                    VStack(alignment: .center, spacing: 40) {
                        customButton(title: "login",
                                     backgroundColor: UIColor(hexString: "#334D92"),
                                     action: self.viewModel.login)
                    }
                }
            }
            Spacer()
        }.alert(item: self.$viewModel.statusViewModel) { status in
            Alert(title: Text(status.title),
                  message: Text(status.message),
                  dismissButton: .default(Text("OK"), action: {
                    if status.title == "Successful" {
                        self.pushActive = true
                    }
                  }))
        }
    }
    
    private func customButton(title: String,
                              backgroundColor: UIColor,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .modifier(ButtonModifier(font: UIConfiguration.buttonFont,
                                         color: backgroundColor,
                                         textColor: .white,
                                         width: 275,
                                         height: 55))
        }
    }
}