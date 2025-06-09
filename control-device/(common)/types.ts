export enum ControlType {
    MOUSE_MOVE = 0,
    MOUSE_DOWN = 1,
    MOUSE_UP = 2,
    MOUSE_INPUT_TEXT = 3,
  
    BACK = 5,
    HOME = 6,
    RECENT = 7,
  
    UNLOCK_SCREEN = 8,
  
    REBOOT = 10,
  
    RERENDER_FRAME = 20,
  
    CONNECT_PROXY = 21,
    DISCONNECT_PROXY = 22,
  
    RESET_FACTORY = 23,
  
    SCREEN_SHOT = 30,
  
    GET_XML = 31,
    GET_CLIPBOARD = 32,
    GET_DEVICE_INFO = 33,
  
    GET_INSTALLED_PACKAGE = 40,
    OPEN_PACKAGE = 41,
    OPEN_APP_INFO = 42,
    FORCE_STOP = 43,
    CLEAR_APP = 44,
    UNINSTALL_APP = 45,
    BACKUP_APP = 46,
    RESTORE_APP = 47,
    CHANGE_DEVICE = 48,
  
    EXECUTE_SINGLE_NODE = 50,
  }

  export const restrictedKeys = [
    "CapsLock",
    "Shift",
    "Tab",
    "Escape", // ESC
    "Control", // CTRL
    "Meta", // WIN
    "Alt", // ALT
    "PageUp",
    "PageDown",
    "Delete",
    "ArrowUp",
    "ArrowDown",
  ];

  export const specialKeyMappings: Record<string, string> = {
    Enter: "[ENTER]",
    Backspace: "[BACKSPACE]",
    ArrowLeft: "[ARROWLEFT]",
    ArrowRight: "[ARROWRIGHT]",
  };
  
  export enum ReportControlType {
    EXPORT_START = 0,
      EXPORT_CONTENT = 1,
      EXPORT_COMPLETE = 2,
  
      EXPORT_LOG = 3,
      EXPORT_CLIPBOARD = 4,
      EXPORT_XML = 5,
      EXPORT_SCREEN_SHOT = 6,
      EXPORT_INSTALLED_PACKAGE = 7,
      EXPORT_DEVICE_INFO = 8,
      EXPORT_FILE = 9,
  
  
      EXPORT_SCREEN_ROTATION = 20,
  }
  
  export enum FileTranferType {
    FILE_METADATA = 0,
    FILE_COMPLETE = 1,
    INSTALL_APK = 2,
    RESTORE_APP = 3,
  }
  