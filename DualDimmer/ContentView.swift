//
//  ContentView.swift
//  DualDimmer
//
//  Created by Francesco Fattori on 13/01/22.
//

import SwiftUI


private struct BlueButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.blue : Color.white)
            .background(configuration.isPressed ? Color.white : Color.blue)
            .cornerRadius(6.0)
            .padding()
    }
}

private struct RedButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.red : Color.white)
            .background(configuration.isPressed ? Color.white : Color.red)
            .cornerRadius(6.0)
            .padding()
    }
}


class GlobalVars: ObservableObject {
    static var shared = GlobalVars()
    @Published var timeout: Float = 3.0
}

struct ContentView: View {
    @EnvironmentObject var globalVars: GlobalVars
    var body: some View {
        VStack(alignment: .leading) {

                    HStack {
                        Text("DualDimmer").padding(.leading)

                        Spacer()

                        Button(action: {
                            print("pressed")
                        }) {
                            Text("Settings")
                                .frame(maxWidth: 70, maxHeight: 30)
                        }.buttonStyle(BlueButtonStyle()).padding(.leading, -30)

                        Button(action: {
                            NSApplication.shared.terminate(self)
                        }) {
                            Text("Quit")
                                .frame(maxWidth: 50, maxHeight: 30)
                        }.buttonStyle(RedButtonStyle()).padding(.leading, -30)
                    }

                    Slider(value: Binding(get: {
                        GlobalVars.shared.timeout
                   }, set: { (newVal) in
                       GlobalVars.shared.timeout = newVal
                       self.sliderChanged(value:newVal)
                   }))
                   .padding(.all)

                    Spacer()


                }.frame(width: 400, height: 100)

            
    }
    
    func sliderChanged(value: Float) {
        UserDefaults.standard.set(value, forKey: "timeout")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
