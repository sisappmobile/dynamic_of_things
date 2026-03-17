// ignore_for_file: constant_identifier_names

enum DynamicFormFieldType {
  SHORT_TEXT,
  LONG_TEXT,
  EMAIL,
  URL,
  NUMBER,
  PHONE_NUMBER,
  DATE,
  TIME,
  DATE_TIME,
  RADIO,
  CHECK,
  DROPDOWN,
  DROPDOWN_DATA,
  FILE,
  FOTO,
  VIDEO,
  SIGNATURE,
  UPLOAD_FOTO,
  UPLOAD_VIDEO,
  UPLOAD_SIGNATURE,
  QRCODE,
  BARCODE,

  STRING,
  NUMERIC;

  static DynamicFormFieldType convert(String dataType) {
    if (dataType == "STRING") {
      return SHORT_TEXT;
    } else if (dataType == "PASSWORD") {
      return SHORT_TEXT;
    } else if (dataType == "NUMERIC") {
      return NUMBER;
    } else if (dataType == "EMAIL") {
      return EMAIL;
    } else if (dataType == "DATE") {
      return DATE;
    } else if (dataType == "DATETIME") {
      return DATE_TIME;
    } else if (dataType == "CHECKBOX") {
      return CHECK;
    } else if (dataType == "COMBOBOX") {
      return DROPDOWN;
    } else if (dataType == "DATA") {
      return DROPDOWN_DATA;
    }

    return SHORT_TEXT;
  }
}