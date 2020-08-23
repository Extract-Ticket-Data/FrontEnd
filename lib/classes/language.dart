class Language{
  final int id;
  final String name;
  final String flag;
  final String languageCode;

  Language(this.id, this.name, this.flag, this.languageCode);

  static List<Language> languageList(){
    return <Language>[
      Language(1,'US','English','en'),
      Language(2,'HI','Hindi','hi'),
      Language(3,'PB','Punjabi','pa'),
      Language(4,'TA','Tamil','ta'),
      Language(5,'TE','Telugu','te'),
      Language(6,'MA', 'Marathi', 'mr'),
      Language(7, 'GJ', 'Gujrati', 'gu')
    ];
  }
}