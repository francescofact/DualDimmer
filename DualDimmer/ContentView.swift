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

struct ComboBox: NSViewRepresentable {
    
    typealias NSViewType = NSPopUpButton
    
    func makeNSView(context: NSViewRepresentableContext<ComboBox>) -> NSPopUpButton {
        let combobox = NSPopUpButton(title:"Screen to Dim", target: context.coordinator, action: #selector(context.coordinator.action))
        loadItems(combobox: combobox)
        
        NotificationCenter.default.addObserver(forName: Notification.Name("PopUpButtonSelectedItemChanged"), object: nil, queue: nil) { _ in
            guard let selected = combobox.selectedItem?.title else { return }
            if (selected == "↻ Reload List"){
                loadItems(combobox: combobox)
            } else {
                print("setting " + selected + " as prefered")
                let id = selected.components(separatedBy: "[")
                let screenid = Int(id[id.count-1].dropLast()) as NSNumber?
                GlobalVars.shared.screenID = screenid
                UserDefaults.standard.set(screenid, forKey: "display")
                print(GlobalVars.shared.screenID)
            }
        }
        
        return combobox
    }
    
    func updateNSView(_ nsView: NSPopUpButton, context: NSViewRepresentableContext<ComboBox>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
        
    class Coordinator {
        @objc func action() {
            NotificationCenter.default.post(name: Notification.Name("PopUpButtonSelectedItemChanged"), object: nil)
        }
    }
    
    func loadItems(combobox: NSPopUpButton){
        combobox.removeAllItems()
        
        let monitors = NSScreen.screens.map{$0.getDeviceName() + " [" + $0.getScreenNumber().stringValue + "]"}
        combobox.addItems(withTitles: monitors)
        combobox.addItem(withTitle: "↻ Reload List")
        if let screenid = UserDefaults.standard.object(forKey: "display") {
            var screen = findScreenByDeviceID(id: screenid as! NSNumber)
            if screen != nil {
                screen = screen.unsafelyUnwrapped
                combobox.selectItem(withTitle: screen!.getDeviceName() + " [" + screen!.getScreenNumber().stringValue + "]")
            }
        }
    }
}



class GlobalVars: ObservableObject {
    static var shared = GlobalVars()
    @Published var timeout: Float = 3
    @Published var enabled: Bool = false
    @Published var screenID: NSNumber? = nil
}

struct ContentView: View {
    @EnvironmentObject var globalVars: GlobalVars
    @State var timeout = 10.0
    var body: some View {
        VStack(alignment: .leading) {

                    HStack {
                        Image("menubar").padding(.leading)
                        Text("DualDimmer")

                        Spacer()

                        Button(action: {
                            GlobalVars.shared.enabled = !GlobalVars.shared.enabled
                            UserDefaults.standard.set(GlobalVars.shared.enabled, forKey: "enabled")
                        }) {
                            Text( GlobalVars.shared.enabled ? "Enabled" : "Disabled")
                                .frame(maxWidth: 70, maxHeight: 30)
                        }.buttonStyle(BlueButtonStyle()).padding(.leading, 0)

                        Button(action: {
                            NSApplication.shared.terminate(self)
                        }) {
                            Text("Quit")
                                .frame(maxWidth: 50, maxHeight: 30)
                        }.buttonStyle(RedButtonStyle()).padding(.leading, -30)
                    }
                    
                    HStack {
                        Text("Timeout Dimming: ")
                        Slider(value: Binding(get: {
                            GlobalVars.shared.timeout
                           }, set: { (newVal) in
                               GlobalVars.shared.timeout = newVal
                               self.sliderChanged(value:newVal)
                           }),
                               in:1...60)
                            
                        Text("\(GlobalVars.shared.timeout, specifier: "%.0f") s")
                    }
                    .padding([.leading, .trailing])
                    
                    HStack {
                        Text("Screen to Dim: ")
                        ComboBox()
                    }
                    .padding([.leading, .trailing, .bottom])
            
                    Text("Developed by Francesco Fattori")
                        .frame(maxWidth: .infinity, alignment: .center)


                }.frame(width: 400, height: 160)

            
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
