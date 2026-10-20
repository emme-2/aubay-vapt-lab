// Profilo Thunderbird preconfigurato per la casella jdoe@corp.local (lab)
// Account IMAP su mail.corp.local, in chiaro (ambiente di laboratorio).
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.account.account1.server", "server1");
user_pref("mail.accountmanager.accounts", "account1");
user_pref("mail.accountmanager.defaultaccount", "account1");
user_pref("mail.accountmanager.localfoldersserver", "server2");

// Identità
user_pref("mail.identity.id1.fullName", "Jane Doe");
user_pref("mail.identity.id1.useremail", "jdoe@corp.local");
user_pref("mail.identity.id1.smtpServer", "smtp1");
user_pref("mail.identity.id1.valid", true);

// Server IMAP in ingresso
user_pref("mail.server.server1.hostname", "mail.corp.local");
user_pref("mail.server.server1.name", "jdoe@corp.local");
user_pref("mail.server.server1.type", "imap");
user_pref("mail.server.server1.port", 143);
user_pref("mail.server.server1.userName", "jdoe");
user_pref("mail.server.server1.socketType", 0);
user_pref("mail.server.server1.authMethod", 3);
user_pref("mail.server.server1.check_new_mail", true);
user_pref("mail.server.server1.login_at_startup", true);

// Local Folders (richiesto da Thunderbird)
user_pref("mail.server.server2.hostname", "Local Folders");
user_pref("mail.server.server2.name", "Local Folders");
user_pref("mail.server.server2.type", "none");
user_pref("mail.server.server2.userName", "nobody");

// SMTP in uscita
user_pref("mail.smtpserver.smtp1.hostname", "mail.corp.local");
user_pref("mail.smtpserver.smtp1.port", 25);
user_pref("mail.smtpserver.smtp1.username", "jdoe");
user_pref("mail.smtpserver.smtp1.authMethod", 3);
user_pref("mail.smtpserver.smtp1.try_ssl", 0);
user_pref("mail.smtpservers", "smtp1");
user_pref("mail.smtp.defaultserver", "smtp1");

// Riduci attriti al primo avvio
user_pref("mail.provider.enabled", false);
user_pref("mailnews.start_page.enabled", false);
user_pref("mail.shell.checkDefaultClient", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("browser.aboutConfig.showWarning", false);
