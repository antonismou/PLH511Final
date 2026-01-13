#include <stdio.h>
#include <stdlib.h>
#include <math.h>

void create_topology(int D, double range_val, const char *filename) {
    int n = D * D;
    int positions[n][2];

    for (int i = 0; i < n; i++) {
        positions[i][0] = i / D;
        positions[i][1] = i % D;
    }

    double distance(int i, int j) {
        int dx = positions[i][0] - positions[j][0];
        int dy = positions[i][1] - positions[j][1];
        return sqrt(dx * dx + dy * dy);
    }

    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        perror("Σφάλμα στο άνοιγμα αρχείου");
        return;
    }

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            if (i != j) {
                double d = distance(i, j);
                if (d <= range_val) {
                    fprintf(file, "%d %d -50.0\n", i, j);
                }
            }
        }
    }

    fclose(file);
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        printf("Χρησιμοποιήστε: %s <διάμετρος> <εμβέλεια> <όνομα_αρχείου>\n", argv[0]);
        return 1;
    }

    int D = atoi(argv[1]);
    double range_val = atof(argv[2]);
    const char *filename = argv[3];

    create_topology(D, range_val, filename);
    printf("Τοπολογία αποθηκεύτηκε στο αρχείο: %s\n", filename);
    return 0;
}