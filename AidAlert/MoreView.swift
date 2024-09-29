import SwiftUI



struct MoreView: View {
    var body: some View {
        NavigationView { // Wrap in NavigationView if you need navigation capabilities
            VStack {
                // Title
                Text("More Options")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                // Content of the More page
                List {
                    Text("Option 1")
                    Text("Option 2")
                    Text("Option 3")
                    Text("Option 4")
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarHidden(true) // Optional: hide navigation bar if not needed
            .background(Color.white) // Set background color to avoid any gaps
        }
    }
}

#Preview {
    MoreView()
}

