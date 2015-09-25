
import java.util.Scanner;

public class extract {
	public static void main(String[] args) {
		Scanner in = new Scanner(System.in);
		while (in.hasNextLine()) {
			String line = in.nextLine();
			line = line.substring(line.indexOf(',') + 1);
			line = line.substring(line.indexOf(',') + 1);

			if (line.charAt(0) == '\"') {
				System.out.println(line.substring(1, line.length() - 1));
			} else {
				System.out.println(line);
			}
		}
	}

}
