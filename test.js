function jikoku() {
    dd = new Date();
    document.F1.T1.value = dd.toLocaleString();
    window.setTimeout("jikoku()", 1000);
}
