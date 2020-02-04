// Copyright (c) 2014-2019, The Monero Project
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification, are
// permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice, this list of
//    conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice, this list
//    of conditions and the following disclaimer in the documentation and/or other
//    materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors may be
//    used to endorse or promote products derived from this software without specific
//    prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import QtQuick 2.9
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.0

import "../js/Wizard.js" as Wizard
import "../js/Utils.js" as Utils
import "../components" as MoneroComponents

Rectangle {
    id: wizardRestoreWallet1

    color: "transparent"
    property alias pageHeight: pageRoot.height
    property string viewName: "wizardRestoreWallet1"

    function verify() {
        if (restoreHeight.text.indexOf('-') === 4 && restoreHeight.text.length !== 10) {
            return false;
        }

        var valid = false;
        if(wizardController.walletRestoreMode === "keys") {
            valid = wizardRestoreWallet1.verifyFromKeys();
            return valid;
        } else if(wizardController.walletRestoreMode === "seed") {
            valid = wizardWalletInput.verify();
            if(!valid) return false;
            valid = Wizard.checkSeed(seedInput.text);
            return valid;
        }

        return false;
    }

    function verifyFromKeys() {
        var result = Wizard.restoreWalletCheckViewSpendAddress(
            walletManager,
            persistentSettings.nettype,
            viewKeyLine.text,
            spendKeyLine.text,
            addressLine.text
        );

        var addressLineLength = addressLine.text.length
        var viewKeyLineLength = viewKeyLine.text.length
        var spendKeyLineLength = spendKeyLine.text.length

        addressLine.error = !result[0] && addressLineLength != 0
        viewKeyLine.error = !result[1] && viewKeyLineLength != 0
        spendKeyLine.error = !result[2] && spendKeyLineLength != 0

        // allow valid viewOnly
        if (spendKeyLine.text.length === 0)
            return (result[0] && result[1])

        return (result[0] && result[1] && result[2])
    }

    function checkRestoreHeight() {
        return (parseInt(restoreHeight) >= 0 || restoreHeight === "") && restoreHeight.indexOf("-") === -1;
    }

    ColumnLayout {
        id: pageRoot
        Layout.alignment: Qt.AlignHCenter;
        width: parent.width - 100
        Layout.fillWidth: true
        anchors.horizontalCenter: parent.horizontalCenter;

        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: wizardController.wizardSubViewTopMargin
            Layout.maximumWidth: wizardController.wizardSubViewWidth
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            WizardHeader {
                title: qsTr("Restore wallet") + translationManager.emptyString
                subtitle: qsTr("Restore wallet from keys or mnemonic seed.") + translationManager.emptyString
            }

            WizardWalletInput{
                id: wizardWalletInput
            }

            RowLayout {
                Layout.topMargin: 10
                spacing: 30
                Layout.fillWidth: true

                MoneroComponents.RadioButton {
                    id: seedRadioButton
                    text: qsTr("Restore from seed") + translationManager.emptyString
                    fontSize: 16
                    checked: true
                    onClicked: {
                        checked = true;
                        keysRadioButton.checked = false;
                        qrRadioButton.checked = false;
                        wizardController.walletRestoreMode = 'seed';
                    }
                }

                MoneroComponents.RadioButton {
                    id: keysRadioButton
                    text: qsTr("Restore from keys") + translationManager.emptyString
                    fontSize: 16
                    checked: false
                    onClicked: {
                        checked = true;
                        seedRadioButton.checked = false;
                        qrRadioButton.checked = false;
                        wizardController.walletRestoreMode = 'keys';
                    }
                }

                MoneroComponents.RadioButton {
                    id: qrRadioButton
                    text: qsTr("Restore from QR Code") + translationManager.emptyString
                    fontSize: 16
                    visible: appWindow.qrScannerEnabled
                    checked: false
                    onClicked: {
                        checked = true;
                        seedRadioButton.checked = false;
                        keysRadioButton.checked = false;
                        wizardController.walletRestoreMode = 'qr';
                        cameraUi.state = "Capture";
                        cameraUi.qrcode_decoded.connect(Wizard.updateFromQrCode);
                    }
                }
            }

            ColumnLayout {
                // seed textarea
                visible: wizardController.walletRestoreMode === 'seed'
                Layout.preferredHeight: 100
                Layout.fillWidth: true

                Rectangle {
                    color: "transparent"
                    radius: 4

                    Layout.preferredHeight: 100
                    Layout.fillWidth: true

                    border.width: 1
                    border.color: {
                        if(seedInput.text !== "" && seedInput.error){
                            return MoneroComponents.Style.inputBorderColorInvalid;
                        } else if(seedInput.activeFocus){
                            return MoneroComponents.Style.inputBorderColorActive;
                        } else {
                            return MoneroComponents.Style.inputBorderColorInActive;
                        }
                    }

                    MoneroComponents.InputMulti {
                        id: seedInput
                        property bool error: false
                        width: parent.width
                        height: 100

                        color: MoneroComponents.Style.defaultFontColor
                        textMargin: 2
                        text: ""

                        font.family: MoneroComponents.Style.fontRegular.name
                        font.pixelSize: 16
                        selectionColor: MoneroComponents.Style.textSelectionColor
                        selectedTextColor: MoneroComponents.Style.textSelectedColor
                        wrapMode: TextInput.Wrap

                        selectByMouse: true

                        MoneroComponents.TextPlain {
                            id: memoTextPlaceholder
                            opacity: 0.35
                            anchors.fill:parent
                            font.pixelSize: 16
                            anchors.margins: 8
                            anchors.leftMargin: 10
                            font.family: MoneroComponents.Style.fontRegular.name
                            text: qsTr("Enter your 25 (or 24) word mnemonic seed") + translationManager.emptyString
                            color: MoneroComponents.Style.defaultFontColor
                            visible: !seedInput.text
                        }
                    }
                }
            }

            MoneroComponents.LineEdit {
                id: addressLine
                visible: wizardController.walletRestoreMode === 'keys'
                Layout.fillWidth: true
                placeholderFontSize: 16
                placeholderText: qsTr("Account address (public)") + translationManager.emptyString

                onTextUpdated: {
                    wizardRestoreWallet1.verifyFromKeys();
                }
            }

            MoneroComponents.LineEdit {
                id: viewKeyLine
                visible: wizardController.walletRestoreMode === 'keys'
                Layout.fillWidth: true
                placeholderFontSize: 16
                placeholderText: qsTr("View key (private)") + translationManager.emptyString

                onTextUpdated: {
                    wizardRestoreWallet1.verifyFromKeys();
                }
            }

            MoneroComponents.LineEdit {
                id: spendKeyLine
                visible: wizardController.walletRestoreMode === 'keys'
                Layout.fillWidth: true
                placeholderFontSize: 16
                placeholderText: qsTr("Spend key (private)") + translationManager.emptyString

                onTextUpdated: {
                    wizardRestoreWallet1.verifyFromKeys();
                }
            }

            GridLayout{
                MoneroComponents.LineEdit {
                    id: restoreHeight
                    Layout.fillWidth: true
                    labelText: qsTr("Wallet creation date as `YYYY-MM-DD` or restore height") + translationManager.emptyString
                    labelFontSize: 14
                    placeholderFontSize: 16
                    placeholderText: qsTr("Restore height") + translationManager.emptyString
                    validator: RegExpValidator {
                        regExp: /^(\d+|\d{4}-\d{2}-\d{2})$/
                    }
                    text: "0"
                }

                Item {
                    Layout.fillWidth: true
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            WizardNav {
                id: nav
                progressSteps: 4
                progress: 1
                btnNext.enabled: wizardRestoreWallet1.verify();
                btnPrev.text: qsTr("Back to menu") + translationManager.emptyString
                onPrevClicked: {
                    wizardStateView.state = "wizardHome";
                }
                onNextClicked: {
                    wizardController.walletOptionsName = wizardWalletInput.walletName.text;
                    wizardController.walletOptionsLocation = wizardWalletInput.walletLocation.text;

                    switch (wizardController.walletRestoreMode) {
                        case 'seed':
                            wizardController.walletOptionsSeed = seedInput.text;
                            break;
                        default: // walletRestoreMode = keys or qr
                            wizardController.walletOptionsRecoverAddress = addressLine.text;
                            wizardController.walletOptionsRecoverViewkey = viewKeyLine.text
                            wizardController.walletOptionsRecoverSpendkey = spendKeyLine.text;
                            break;
                    }

                    var _restoreHeight = 0;
                    if(restoreHeight.text){
                        // Parse date string or restore height as integer
                        if(restoreHeight.text.indexOf('-') === 4 && restoreHeight.text.length === 10){
                            _restoreHeight = Wizard.getApproximateBlockchainHeight(restoreHeight.text, Utils.netTypeToString());
                        } else {
                            _restoreHeight = parseInt(restoreHeight.text)
                        }

                        wizardController.walletOptionsRestoreHeight = _restoreHeight;
                    }

                    wizardStateView.state = "wizardRestoreWallet2";
                }
            }
        }
    }

    function onPageCompleted(previousView){
        if(previousView.viewName == "wizardHome"){
            // cleanup
            wizardWalletInput.reset();
            seedInput.text = "";
            addressLine.text = "";
            spendKeyLine.text = "";
            viewKeyLine.text = "";
            restoreHeight.text = "";
        }
    }
}
