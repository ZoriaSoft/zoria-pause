// Shizuku server sürecinden (shell/root uid) çağrılır — izin verme işleminin
// kendisi burada yürür. Yüzey bilinçli olarak tek metot: saldırı alanı minimal.
// Parametre yok: çağıran-verdi paket adı confused-deputy yüzeyidir (Shizuku
// zaten çağıranı enforce eder); hedef paket serviste sabit literal'dir
// (fleet review sertleştirmesi, 2026-09-21).
package com.zoriasoft.zoriapause;

interface IPauseGrantService {
    int grantSecureSettings();
}
