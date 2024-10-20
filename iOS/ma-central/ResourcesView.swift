//
//  ResourcesView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 10/19/24.
//

import SwiftUI

struct ResourcesView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        NavigationLink(destination: ChatbotView().environmentObject(appState)) {
                            Text("Find a resource with our chatbot")
                        }
                    }
                    Section {
                        Text("[Peace & Wellness Space](https://www.mabears.org/Counseling/Social--Emotional-Support-Staff/Wellness-Resources/index.html)")
                        Text("Open 9am to 3pm Monday through Friday. Access to mental health, substance abuse, and overall wellness services via partnerships with Star Vista, Miricenter, and Acknowledge Alliance. Drop in for crisis intervention, wellness check-ins, or to practice coping strategies. You may refer yourself or a friend by using the link above or by scanning the QR codes posted around campus.")
                    }
                    Section {
                        Text("[Counselors & Appointments](https://www.mabears.org/Counseling/index.html)")
                        Text("The school has counselors available by appointment via the link above or the counseling menu on [mabears.org](mabears.org). For 504 plan support, students can reach out to Intervention Counselors Kerry Larratt (A-L) or Andrea Booth (M-Z) for personalized assistance.")
                    }
                    Section {
                        HStack {
                            Text("Care Solace")
                            Spacer()
                            Text("[1 (855) 515-0595](tel://18555150595)")
                        }
                        Text("24/7/365 support to connect students and families to treatment providers anonymously, available at the Care Solace website or by calling the number above. Services are available in 200+ languages and accomodate all types of insurance or no insurance.")
                    }
                    Section {
                        HStack {
                            Text("Star Vista S.O.S.")
                            Spacer()
                            Text("[1 (650) 579-0350](tel://16505790350)")
                        }
                        Text("Provides crisis intervention for all youth.")
                    }
                    Section {
                        HStack {
                            Text("Kara Grief Services")
                            Spacer()
                            Text("[1 (650) 321-5272](tel://16503215272)")
                        }
                        Text("Offers grief support for those dealing with loss, available at the phone number above or the Kara Grief website.")
                    }
                    Section {
                        HStack {
                            Text("Suicide & Crisis Lifeline")
                            Spacer()
                            Text("[988](tel://988)")
                        }
                        Text("Or, text \"Help\" to [988](sms://988)")
                    }
                    Section {
                        HStack {
                            Text("CA Youth Crisis Line")
                            Spacer()
                            Text("[1 (800) 843-5200](tel://18008435200)")
                        }
                    }
                    Section {
                        HStack {
                            Text("Trevor Project Lifeline")
                            Spacer()
                            Text("[1 (866) 488-7386](tel://18664887386)")
                        }
                        Text("Or, text \"START\" to [678678](sms://678678)")
                    }
                }
            }
            .navigationTitle("Resources")
        }
    }
}

#Preview {
    ResourcesView()
}
