package main

import (
	"bufio"
	"fmt"
	"log"
	"os"

	"golang.org/x/crypto/ssh"
	// Uncomment to store output in variable
	//"bytes"
)

type MachineDetails struct {
	username, password, hostname, port string
}

func readlines(path string) ([]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	return lines, scanner.Err()
}
func main() {
	lines, err := readlines("<IPAdressesListOfYourSwitches.txt>")
	if err != nil {
		log.Fatalf("readLines: %s", err)
	}
	for i, line := range lines {
		fmt.Println(i, line)
		h1 := MachineDetails{"<Username>", "<Password>", line, "22"}

		// Uncomment to store output in variable
		//var b bytes.Buffer
		//sess.Stdout = &amp;b
		//sess.Stderr = &amp;b

		commands := []string{
			"<ShowCommandOfYourSwitch>",
			"exit",
		}

		connectHost(h1, commands)

	}
	// Uncomment to store in variable
	//fmt.Println(b.String())

}

func connectHost(hostParams MachineDetails, commands []string) {

	// SSH client config
	config := &ssh.ClientConfig{
		User: hostParams.username,
		Auth: []ssh.AuthMethod{
			ssh.Password(hostParams.password),
		},
		// Non-production only
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	// Connect to host
	client, err := ssh.Dial("tcp", hostParams.hostname+":"+hostParams.port, config)
	if err != nil {
		log.Fatal(err)
	}
	defer client.Close()

	// Create sesssion
	sess, err := client.NewSession()
	if err != nil {
		log.Fatal("Failed to create session: ", err)
	}
	defer sess.Close()

	// Enable system stdout
	// Comment these if you uncomment to store in variable
	outfile, err := os.Create(hostParams.hostname + ".txt")
	if err != nil {
		panic(err)
	}
	defer outfile.Close()
	sess.Stdout = outfile
	sess.Stderr = outfile

	// StdinPipe for commands
	stdin, err := sess.StdinPipe()
	if err != nil {
		log.Fatal(err)
	}

	// Start remote shell
	err = sess.Shell()
	if err != nil {
		log.Fatal(err)
	}

	// send the commands

	for _, cmd := range commands {
		_, err = fmt.Fprintf(stdin, "%s\n", cmd)
		if err != nil {
			log.Fatal(err)
		}
	}

	// Wait for sess to finish
	err = sess.Wait()
	if err != nil {
		log.Fatal(err)
	}

	// return sess, stdin, err
}

func createSession() {

}
