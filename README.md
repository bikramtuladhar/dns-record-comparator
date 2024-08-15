# DNS Record Comparator

This bash script is designed to extract DNS records from a specified zone file and compare them against two different DNS servers. The comparison helps identify discrepancies in DNS configurations across different servers, which is useful for maintaining consistent DNS setups.

## Features

- Extracts DNS records from a zone file.
- Compares the extracted records against two target DNS servers.
- Provides a detailed report on differences between the DNS records, highlighting errors and warnings.
- Supports multiple DNS record types, including A, AAAA, CNAME, MX, NS, SOA, TXT, PTR, SRV, CAA, and others.

## Usage

### Command Syntax

```bash
./dns_record_comparator.sh ZONE Target_Server_1 Target_Server_2 zone_file
```

### Arguments

- **ZONE**: The domain zone to query (e.g., `example.com`).
- **Target_Server_1**: The first DNS server to query.
- **Target_Server_2**: The second DNS server to query.
- **zone_file**: Path to the zone file to extract records from.

### Example

```bash
./dns_record_comparator.sh example.com 1.2.3.4 5.6.7.8 /path/to/zonefile.txt
```

### Options

- `-h` or `--help`: Display help text.

## Output

The script outputs the following:

- **OK**: The DNS record is consistent across both servers.
- **WARN**: The SOA or NS records differ between the servers.
- **ERROR**: Any other DNS record type differs between the servers.

At the end of the comparison, the script provides a summary of the number of errors and warnings encountered.

## Prerequisites

- `dig` command should be installed and accessible in your system's `PATH`.
- Basic knowledge of DNS and zone files.

## Exit Codes

- **0**: No errors found.
- **1**: Errors were found during the comparison.

## License

This script is released under the MIT License. See the `LICENSE` file for more details.

---