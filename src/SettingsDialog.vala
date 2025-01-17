using Gtk;
using GLib;

public class moserial.SettingsDialog : GLib.Object
{
	// Does anyone have more than 32 serial ports?
	const int max_devices = 32;

        public Builder builder {get; construct;}
        private Settings currentSettings;
        private Dialog dialog;
        private Button cancelButton;
        private Button okButton;
        private Settings settings;
        private ComboBoxEntry deviceCombo;
        private ComboBox baudRateCombo;
        private ComboBox dataBitsCombo;
        private ComboBox stopBitsCombo;
        private ComboBox parityCombo;
        private CheckButton hardwareHandshake;
        private CheckButton softwareHandshake;
        private ComboBox accessModeCombo;
        private CheckButton localEcho;
        public signal void updateSettings(Settings settings);
        public SettingsDialog(Builder builder) {
                this.builder=builder;
        }

        construct {
                dialog = (Dialog)builder.get_object("settings_dialog");
                cancelButton = (Button)builder.get_object("settings_cancel_button");
                okButton = (Button)builder.get_object("settings_ok_button");

                deviceCombo = (ComboBoxEntry)builder.get_object("settings_device");
                baudRateCombo = (ComboBox)builder.get_object("settings_baud_rate");
                dataBitsCombo = (ComboBox)builder.get_object("settings_data_bits");
                stopBitsCombo = (ComboBox)builder.get_object("settings_stop_bits");
                parityCombo = (ComboBox)builder.get_object("settings_parity");
                hardwareHandshake = (CheckButton)builder.get_object("settings_hardware_handshake");
                softwareHandshake = (CheckButton)builder.get_object("settings_software_handshake");
                accessModeCombo = (ComboBox)builder.get_object("settings_open_for");
                localEcho = (CheckButton)builder.get_object("settings_local_echo");
                dialog.delete_event += hide;
                cancelButton.clicked += this.cancel;
                okButton.clicked += this.ok;
                
		populateDevices();

        }

        private void populateDevices(){
		List<string> deviceTypes = new List<string> ();
		deviceTypes.append ("/dev/ttyS");
		deviceTypes.append ("/dev/ttyUSB");
		deviceTypes.append ("/dev/rfcomm");

                var ls = new ListStore(2, typeof(string), typeof(string));
                
                deviceCombo.set_model(ls);
                deviceCombo.set_text_column(1);
                TreeIter iter;
		
		foreach (string devType in deviceTypes) {
			for (int i = 0; i < max_devices; i++) {
				string dev = "%s%d".printf(devType,i);
				if (FileUtils.test (dev, FileTest.EXISTS)) {
		 			ls.append(out iter);
        		        	ls.set(iter, 0, "", 1, dev, -1);
				}
			}
		}
        }

        public void show(Settings settings) {
                this.currentSettings = settings;
                loadSettings();
                dialog.show_all();
        }

        // Load the current settings into the dialog
        public void loadSettings() {
                TreeModel t;
                TreeIter ti;
                bool success;
                
                //Device
                t = deviceCombo.get_model();
                success = t.get_iter_first(out ti);
                while (success) {
                        Value str_data;
                        t.get_value(ti, 1, out str_data);
                        if (str_data.get_string()==currentSettings.device)
                                deviceCombo.set_active_iter(ti);
                        success = t.iter_next (ref ti);
                }

                //Baud Rate
                t = baudRateCombo.get_model();
                success = t.get_iter_first(out ti);
                while (success) {
                        Value str_data;
                        t.get_value(ti, 0, out str_data);
                        if (str_data.get_string()=="%i".printf(currentSettings.baudRate))
                                baudRateCombo.set_active_iter(ti);
                        success = t.iter_next (ref ti);
                }

                //Data Bits
                t = dataBitsCombo.get_model();
                success = t.get_iter_first(out ti);
                while (success) {
                        Value str_data;
                        t.get_value(ti, 0, out str_data);
                        if (str_data.get_string()=="%i".printf(currentSettings.dataBits))
                                dataBitsCombo.set_active_iter(ti);
                        success = t.iter_next (ref ti);
                }

                //Stop Bits
                t = stopBitsCombo.get_model();
                success = t.get_iter_first(out ti);
                while (success) {
                        Value str_data;
                        t.get_value(ti, 0, out str_data);
                        if (str_data.get_string()=="%i".printf(currentSettings.stopBits))
                                stopBitsCombo.set_active_iter(ti);
                        success = t.iter_next (ref ti);
                }

		parityCombo.set_active((int)currentSettings.parity);
		accessModeCombo.set_active((int)currentSettings.accessMode);

                hardwareHandshake.set_active(false);
                softwareHandshake.set_active(false);
                if (currentSettings.handshake==Settings.Handshake.BOTH || currentSettings.handshake==Settings.Handshake.HARDWARE)
                        hardwareHandshake.set_active(true);
                if (currentSettings.handshake==Settings.Handshake.BOTH || currentSettings.handshake==Settings.Handshake.SOFTWARE)
                        softwareHandshake.set_active(true);
                if(currentSettings.localEcho)
                	localEcho.set_active(true);
                else
                	localEcho.set_active(false);
        }

        public bool hide(Widget w) {
                dialog.hide_all();
                return true;
        }

        public void cancel(Widget w) {
                currentSettings=null;
                hide(w);
        }

        public void ok(Widget w) {

                string device;
                int baudRate;
                int dataBits;
                int stopBits;
                Settings.Parity parity;
                Settings.Handshake handshake;
                Settings.AccessMode accessMode;
                bool pLocalEcho;
                device = deviceCombo.get_active_text();
                baudRate = baudRateCombo.get_active_text().to_int();
                dataBits = dataBitsCombo.get_active_text().to_int();
                stopBits = stopBitsCombo.get_active_text().to_int();

		/* Glade choices must be in same order as Settings enums */
                parity = (Settings.Parity)parityCombo.get_active();
                accessMode = (Settings.AccessMode)accessModeCombo.get_active();

                if (hardwareHandshake.get_active() && softwareHandshake.get_active())
                        handshake=Settings.Handshake.BOTH;
                else if (hardwareHandshake.get_active())
                        handshake=Settings.Handshake.HARDWARE;
                else if (softwareHandshake.get_active())
                        handshake=Settings.Handshake.SOFTWARE;
                else
                        handshake=Settings.Handshake.NONE;
		pLocalEcho = localEcho.get_active();
                settings = new Settings(device, baudRate, dataBits, stopBits, parity, handshake, accessMode, pLocalEcho);
                currentSettings = settings;
                this.updateSettings(currentSettings);
                this.hide(w);
        }
}
